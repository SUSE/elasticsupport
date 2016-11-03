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
require 'elasticsupport/logstash'
require 'elasticsupport/filebeat'

module Elasticsupport

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

    # constructor
    #
    # opens DB connection
    #
    # @param [Object] Directory of unpacked supportconfig data
    #                 or [Enumerable] TarReader
    #
    def initialize handle, elastic
      @client = Elasticsearch::Client.new # log: true
      if handle.is_a? Enumerable
        # assume TarReader
      else
        # assume directory name
        raise "#{handle.inspect} is not a directory" unless File.directory?(handle)
      end
      @handle = handle
      @elastic = elastic
      @timestamp = nil
      @hostname = nil
      @done = []
    end

    # index list of file
    #
    # @param [Array] list of files to import from
    #
    def index files = []
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
      unless @hostname
        raise "Couldn't determine hostname !"
      end
    end # def index

    # check for spacewalk-debug
    #
    # only works for unpacked directories
    #
    def spacewalk files=[]
      unless @hostname
        STDERR.puts "No hostname, running index"
        index # parse basic-environment.txt
      end
      @logstash = Logstash.new @elastic, @hostname, @timestamp
      @logstash.run @handle, files
      @filebeat = Filebeat.new @elastic, @hostname, @timestamp
      @filebeat.run @handle, files
    end
  end # class

end # module Elasticsupport
