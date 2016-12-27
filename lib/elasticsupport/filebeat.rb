#encoding: utf-8
#
# filebeat.rb
#
# Filebeat connector for 'elasticsupport' library
#
# - Creates filebeat.yml from filebeat/filebeat.yml.erb
# - Runs filebeat for the respective supportconfig data
#
# Copyright (c) 2016 SUSE LINUX GmbH
# Written by Klaus Kämpf <kkaempf@suse.de>
#
# See MIT-LICENSE at toplevel for license information
#

require 'rubygems'
require 'logger'
require 'socket'
require 'erb'

module Elasticsupport
  YMLFILE = 'filebeat.yml'
  ERBFILE = YMLFILE+'.erb'

  class Filebeat

    # initialize with hostname and timestamp of the supportconfig
    def initialize elastic, hostname, timestamp
      @elastic = elastic
      @hostname = hostname
      @timestamp = timestamp
      @dirname = File.dirname(__FILE__)
      @filebeatdir = File.expand_path(File.join(@dirname, "..", "..", "filebeat"))
    end

    def run handle, files = []
      unless File.directory?(handle)
        STDERR.puts "Filebeat: Not a directory - #{handle.inspect}"
        return
      end
      debugdir = File.join(handle, 'spacewalk-debug')
      unless File.directory?(debugdir)
        STDERR.puts "spacewalk-debug isn't unpacked in #{handle.inspect}"
        Dir.chdir(handle) do
          system("tar xf spacewalk-debug.tar.bz2")
        end
      end
      begin
        socket = TCPSocket.open('localhost', 5045)
        socket.close
      rescue Errno::ECONNREFUSED
        STDERR.puts "Please start logstash first"
        exit 1
      end
      out = create_yml debugdir
      puts "Running filebeat"
      # remove 'last sync point' file to force filebeat to transfer files completely
      File.delete(".filebeat") rescue nil
      system "filebeat -c #{out}"
      puts "Stopped filebeat"
    end

    private
    def create_yml root
      apache_prefix = File.join(root, 'httpd-logs')
      rhn_prefix = File.join(root, 'rhn-logs')
      erb = ""
      File.open(File.join(@filebeatdir, ERBFILE), "r") do |f|
        erb = ERB.new f.read
      end
      out = File.join(@filebeatdir, YMLFILE)
      File.open(out, "w+") do |f|
        f.write erb.result(binding)
      end
      out
    end
  end # class

end # module
