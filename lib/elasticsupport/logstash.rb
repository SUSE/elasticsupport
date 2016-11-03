#encoding: utf-8
#
# logstash.rb
#
# Logstash connector for 'elasticsupport' library
#
# Copyright (c) 2016 SUSE LINUX GmbH
# Written by Klaus Kämpf <kkaempf@suse.de>
#
# See MIT-LICENSE at toplevel for license information
#

require 'rubygems'
require 'logger'

module Elasticsupport
  
  class Logstash

    # initialize with hostname and timestamp of the supportconfig
    def initialize elastic, hostname, timestamp
      @elastic = elastic
      @hostname = hostname
      @timestamp = timestamp
      @dirname = File.dirname(__FILE__)
      @logstashdir = File.expand_path(File.join(@dirname, "..", "..", "logstash"))
    end

    def run handle, files = []
      create_output
    end

    private

    #
    # create_output
    # creates output.conf, pointing to correct index
    #
    def create_output
      # create logstash configs
      indexname = sprintf("%s_%02d%02d%02d_%02d%02d", @hostname, @timestamp.year % 100, @timestamp.mon, @timestamp.day, @timestamp.hour, @timestamp.min)
      File.open(File.join(@logstashdir, "output.conf"), "w") do |f|
        f.write <<OUTPUT
# Generated by elasticsupport
output {
  elasticsearch {
    template => "elasticsupport-template.json"
    template_overwrite => true
    hosts => ["#{@elastic}"]
    index => #{indexname.inspect}
  }
  if ("_grokparsefailure" in [tags]) {
    stdout { codec => rubydebug }
  }
}
OUTPUT
      end
    end

    def throughput start, count
      duration = Time.now - start
      lps = count / duration
      STDERR.puts "#{count} lines in #{duration} seconds: #{lps} lines per second"
    end
    #
    # logpipe
    # pipe log from <directory>/<path> to socket
    #
    def logpipe directory, path, socket
      # save for later retry if connection is reset (logstash restart)
      address_family, port, hostname, numeric_address = socket.peeraddr(:numeric)
      # move directory parts from path to directory
      local_dir = File.dirname(path)
      filepattern = Regexp.new(File.basename(path))
      directory = File.join(directory, local_dir)
#      STDERR.puts "logpipe #{directory} #{filepattern}"

      files = []
      Dir.open(directory).each do |entry|
#        STDERR.puts "logpipe #{entry} =~ #{filepattern}"
        next unless entry =~ filepattern
        files << entry
      end
      STDERR.puts "-- sorting --"
      files.sort!
      # put first (current) file last
      current = files.shift
      files.push current
      
      Dir.chdir(directory) do
        files.each do |entry|
          next unless entry
          next if entry[0,1] == "."
          unless File.readable?(entry)
            STDERR.puts "*** Not readable: #{entry}"
            next
          end
          case entry
          when /\.gz$/
            system "gunzip #{entry}"
            entry = File.basename(entry, ".gz")
          when /\.bz2$/
            system "bunzip2 #{entry}"
            entry = File.basename(entry, ".bz2")
          when /\.xz$/
            system "unxz #{entry}"
            entry = File.basename(entry, ".xz")
          end
          STDERR.puts "#{entry}"
        
#      socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1) #Nagle
          STDERR.puts "Piping #{entry} to logstash @ #{numeric_address}:#{port}"
          File.open(entry) do |f|
            start = Time.now
            count = 0
            f.each do |l|
              loop do
                begin
                  socket.puts l
                  count += 1
                  break
                rescue Errno::ECONNRESET
                  STDERR.puts "Retry"
                  socket.close
                  sleep 2
                  socket = TCPSocket.open(numeric_address, port)
                  sleep 2
                end
              end
              if count % 10000 == 0
                throughput start, count
              end
            end
            socket.flush
            throughput start, count
          end
        end
      end # chdir
    end

  end # class

end # module
