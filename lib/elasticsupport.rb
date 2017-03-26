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

    attr_reader :client, :logstash, :elastic
    attr_accessor :name

    # constructor
    #
    # opens DB connection
    #
    # @param [Object] Directory of unpacked supportconfig data
    #                 or [Enumerable] TarReader
    #
    def initialize handle, elastic
#      puts "#{self.class}.initialize #{handle.class}:#{handle.inspect}"
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
    end
private
    # import single file
    def import_single name, file
      # convert filename to class name
      # foo.bar -> foo_bar
      # foo-bar -> FooBar
      klassname = name.tr(".", "_").split("-").map{|s| s.capitalize}.join("")
      begin
        klass = ::Elasticsupport.const_get("Content::#{klassname}")
      rescue NameError
        STDERR.puts "Parser missing for #{file}"
        return
      end
      #          puts "Found class #{klass}"
      return unless klass.to_s =~ /Elasticsupport::Content/ # ensure Module 'Elasticsupport'
      begin
        # create instance (parses file, writes to DB)
        klass.new self, @handle, file
      rescue Faraday::ConnectionFailed
        STDERR.puts "Elasticsearch DB not running"
      end
    end
    # import list of file
    #
    # @param [Array] list of files to import from
    #
    def import_many files
      # set @name
      import_single "supportconfig", "supportconfig.txt"
      # check for already imported files
      content = Content::Content.new self, @handle
      already = content._read :content, self.name
      id = nil
      if already
        id = already["_id"]
        already = already["_source"]["files"]
      else
        already = []
      end
      files.each do |entry|
        if already.include? entry
          puts "Have #{entry} already, skipping"
          next
        end
        next unless entry =~ /^(.*)\.txt$/
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
          exit 1
        end
      end
      unless @name
        raise "Couldn't determine name !"
      end
      if id
        content._update :content, id, { doc: { files: (files + already).uniq } }
      else
        content._write :content, files: files
      end
    end # def import_many
public
    # consume supportconfig files
    #
    def consume files=[]
      default_files = [ "basic-environment.txt", "hardware.txt" ] # , "rpm.txt" ]
      import_many default_files + files
      @logstash = Logstash.new @elastic, @name
      @logstash.run @handle, files
      @filebeat = Filebeat.new @elastic, @name
      @filebeat.run @handle, files
      STDERR.puts "Waiting for logstash process #{@logstash.job} ..."
      Process.kill( "INT", @logstash.job )
      Process.wait( @logstash.job )
    end
  end # class

end # module Elasticsupport
