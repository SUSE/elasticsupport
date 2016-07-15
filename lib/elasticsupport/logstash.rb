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
  # logstash
  PORT = 9000
  HOST = 'localhost'
  
  LOGS = [
    'httpd-logs/apache2/access_log',
    'httpd-logs/apache2/error_log',
    'rhn-logs/rhn/rhn_web_api.log',
    'rhn-logs/rhn/osa-dispatcher.log'
  ]

  class Logstash
    
    def initialize hostname, timestamp
      @hostname = hostname
      @timestamp = timestamp
      @dirname = File.dirname(__FILE__)
      @logstashdir = File.expand_path(File.join(@dirname, "..", "..", "logstash"))
    end

    def spacewalk handle
      unless File.directory?(handle)
        STDERR.puts "Logstash: Not a directory - #{handle.inspect}"
        return
      end
      debugdir = File.join(handle, 'spacewalk-debug')
      unless File.directory?(debugdir)
        STDERR.puts "spacewalk-debug isn't unpacked in #{handle.inspect}"
        Dir.chdir(handle) do
          system("tar xf spacewalk-debug.tar.bz2")
        end
      end
      LOGS.each do |file|
        logpipe debugdir, file
      end
    end

    private

    # pipe log from <directory>/<path> to logstash
    def logpipe directory, path
      logfile = File.join( directory, path )
      unless File.readable?(logfile)
        STDERR.puts "*** No such file: #{logfile}"
        return
      end
      
      # create logstash configs
      indexname = sprintf("%s_%02d%02d%02d_%02d%02d", @hostname, @timestamp.year % 100, @timestamp.mon, @timestamp.day, @timestamp.hour, @timestamp.min)
      File.open(File.join(@logstashdir, "output.conf"), "w") do |f|
        f.write <<OUTPUT
output {
  elasticsearch {
    hosts => ["localhost:9200"]
    index => #{indexname.inspect}
  }
}
OUTPUT
      end

      begin
        socket = TCPSocket.open(HOST, PORT)
      rescue Errno::ECONNREFUSED
        STDERR.puts "*** Can't logstash #{logfile}:"
        STDERR.puts "*** Logstash is not listening on #{HOST}:#{PORT}"
        exit 1
      end
#      socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1) #Nagle
      STDERR.puts "Piping #{logfile} to logstash"
      File.open(logfile) do |f|
        f.each do |l|
          socket.puts l
          socket.flush
        end
      end
      socket.close
    end

  end # class

end # module
