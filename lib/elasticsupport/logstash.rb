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
    
    def self.spacewalk debugdir
      GROKS.each do |file,config|
        logpipe debugdir, file, config
      end
    end

    private

    # pipe log from <directory>/<path> to logstash running with <config>
    def self.logpipe directory, path, config
      cwd = File.dirname(__FILE__)
      logfile = File.join( directory, path )
      unless File.readable?(logfile)
        STDERR.puts "*** No such file: #{logfile}"
        return
      end

      Dir.chdir File.join(cwd, "..", "..", "logstash")
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

      File.open(logfile) do |f|
        f.each do |l|
          socket.write l
        end
      end
      Dir.chdir cwd

      socket.close
    end

  end # class

end # module
