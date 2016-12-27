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
require 'elasticsupport/logstash'
require 'elasticsupport/filebeat'
require 'elasticsupport/content'

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
    attr_accessor :name

    # constructor
    #
    # opens DB connection
    #
    # @param [Object] Directory of unpacked supportconfig data
    #                 or [Enumerable] TarReader
    #
    def initialize handle, elastic
      puts "#{self.class}.initialize #{handle.class}:#{handle.inspect}"
      @client = Elasticsearch::Client.new # log: true
      if handle.is_a? Enumerable
        # assume TarReader
      else
        # assume directory name
        raise "#{handle.inspect} is not a directory" unless File.directory?(handle)
      end
      @handle = handle
      @elastic = elastic
      @name = nil
      @done = []
    end

    # index list of file
    #
    # @param [Array] list of files to import from
    #
    def index files = []
      files.each do |entry|
        next unless entry =~ /^(.*)\.txt$/
        next if @done.include? entry
        @done << entry
        puts "*** #{entry} <#{@handle.inspect}>"
        # convert filename to class name
        # foo.bar -> foo_bar
        # foo-bar -> FooBar
        klassname = $1.tr(".", "_").split("-").map{|s| s.capitalize}.join("")
        begin
          begin
            klass = ::Elasticsupport.const_get("Content::#{klassname}")
          rescue NameError
            STDERR.puts "Parser missing for #{entry}"
            next
          end
#          puts "Found class #{klass}"
          next unless klass.to_s =~ /Elasticsupport::Content/ # ensure Module 'Elasticsupport'
          # create instance (parses file, writes to DB)
          klass.new self, @handle, entry
#        rescue NameError => e
#          STDERR.puts "#{e}\n\t#{entry} - not implemented"
        rescue Faraday::ConnectionFailed
          STDERR.puts "Elasticsearch DB not running"
        end
      end
      unless @name
        raise "Couldn't determine name !"
      end
    end # def index

    # consume supportconfig files
    #
    def consume files=[]
      default_files = [ "supportconfig.txt", "basic-environment.txt", "hardware.txt" ]#, "rpm.txt" ]
      index default_files + files
#      @logstash = Logstash.new @elastic, @name
#      @logstash.run @handle, files
#      @filebeat = Filebeat.new @elastic, @name
#      @filebeat.run @handle, files
    end
  end # class

end # module Elasticsupport
