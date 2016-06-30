#encoding: utf-8
#
# elasticsupport.rb
#
# Main entry point into 'elasticsupport' library
#
# Copyright (c) 2016 SUSE LINUX GmbH
# Written by Klaus Kämpf <kkaempf@suse.de>
#
# See MIT-LICENSE at toplevel for license information
#

require 'rubygems'
require 'logger'
require 'supportconfig'
require 'elasticsupport/version'
require 'elasticsupport/logging'
require 'elasticsupport/supportconfig'
require 'elasticsupport/basic_environment'
require 'elasticsupport/rpm'
require 'elasticsupport/hardware'

module Elasticsupport
  # logstash
  PORT = 9000
  HOST = 'localhost'

  #
  # class Elasticsupport
  #
  # scan suppportconfig directory, build class name from file name
  # initialize class instance (does parsing)
  #
  class Elasticsupport
    require 'elasticsearch'

    attr_reader :client
    attr_accessor :timestamp, :hostname

    private

    # pipe log from <directory>/<path> to logstash running with <config>
    def logpipe directory, path, config
      logfile = File.join( directory, path )
      unless File.readable?(logfile)
        STDERR.puts "*** No such file: #{logfile}"
        return
      end

      Dir.chdir File.join(@cwd, "..", "logstash")
      system ("cp #{config} config/filter.conf")
      sleep 5
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
      Dir.chdir @cwd

      socket.close
    end

    public
    # constructor
    #
    # opens DB connection
    #
    # @param [Object] Directory of unpacked supportconfig data
    #                 or [Enumerable] TarReader
    #
    def initialize handle
      @client = Elasticsearch::Client.new # log: true
      if handle.is_a? Enumerable
        # assume TarReader
      else
        # assume directory name
        raise "#{handle.inspect} is not a directory" unless File.directory?(handle)
      end
      @handle = handle
      @timestamp = nil
      @hostname = nil
      @done = []
      @cwd = File.dirname(__FILE__)
    end

    # index list of file
    #
    # @param [Array] list of files to import from
    #
    def index files
      files.unshift 'basic-environment.txt' # get timestamp and hostname first
      files.each do |entry|
        next unless entry =~ /^(.*)\.txt$/
        next if @done.include? entry
        @done << entry
        puts "*** #{entry} <#{@handle.inspect}>"
        if $1 == "supportconfig"
          raise "Please remove 'supportconfig.txt from list of files to index"
        end
        # convert filename to class name
        # foo.bar -> foo_bar
        # foo-bar -> FooBar
        klassname = $1.tr(".", "_").split("-").map{|s| s.capitalize}.join("")
        begin
          begin
            klass = ::Elasticsupport.const_get(klassname)
          rescue NameError
            STDERR.puts "Parser missing for #{entry}"
            next
          end
          next unless klass.to_s =~ /Elasticsupport/ # ensure Module 'Elasticsupport'
          # create instance (parses file, writes to DB)
          klass.new self, @handle, entry
#        rescue NameError => e
#          STDERR.puts "#{e}\n\t#{entry} - not implemented"
        rescue Faraday::ConnectionFailed
          STDERR.puts "Elasticsearch DB not running"
        end
      end
    end # def index

    # check for spacewalk-debug
    #
    # only works for unpacked directories
    #
    def spacewalk
      unless File.directory?(@handle)
        return
      end
      debugdir = File.join(@handle, 'spacewalk-debug')
      return unless File.directory?(debugdir)
      # grok filter configs
      { 'httpd-logs/apache2/access_log' => 'access_log.conf',
        'httpd-logs/apache2/error_log' => 'error_log.conf',
      }.each do |file,config|
        logpipe debugdir, file, config
      end
    end
  end # class

end # module Elasticsupport
