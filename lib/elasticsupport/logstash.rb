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
  
  GROKS = {      # grok filter configs
#    'httpd-logs/apache2/access_log' => 'access_log.conf',
#    'httpd-logs/apache2/error_log' => 'error_log.conf',
    'rhn-logs/rhn/rhn_web_api.log' => 'rhn_web_api.conf'
  }

  class Logstash
    
    def initialize hostname, timestamp
      indexname = sprintf("logstash-%s_%02d%02d%02d_%02d%02d", hostname, timestamp.year % 100, timestamp.mon, timestamp.day, timestamp.hour, timestamp.min)
      @dirname = File.dirname(__FILE__)
      @logstashdir = File.expand_path(File.join(@dirname, "..", "..", "logstash"))
      @configdir = File.join(@logstashdir, "config")
      File.open(File.join(@configdir, "output.conf"), "w") do |f|
        f.write <<OUTPUT
output {
  elasticsearch {
    hosts => ["localhost:9200"]
    index => #{indexname.inspect}
  }
}
OUTPUT
      end
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
      GROKS.each do |file, config|
        logpipe debugdir, file, config
      end
    end

    private

    # pipe log from <directory>/<path> to logstash running with <config>
    def logpipe directory, path, config
      logfile = File.join( directory, path )
      unless File.readable?(logfile)
        STDERR.puts "*** No such file: #{logfile}"
        return
      end

      Dir.chdir(@logstashdir) do
        system ("cp #{config} config/filter.conf")
        sleep 5 # logstash needs ~3 secs to detect the config change
        puts "Grokfilter #{Dir.pwd}/#{config}"

        begin
          socket = TCPSocket.open(HOST, PORT)
        rescue Errno::ECONNREFUSED
          STDERR.puts "*** Can't logstash #{logfile}:"
          STDERR.puts "*** Logstash is not listening on #{HOST}:#{PORT}"
          exit 1
        end
STDERR.puts "Piping #{logfile} to logstash"
        File.open(logfile) do |f|
          f.each do |l|
            socket.write l
          end
        end
        socket.close
      end

    end

  end # class

end # module
