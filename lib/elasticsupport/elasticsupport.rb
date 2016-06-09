#
# elasticsupport.rb
#
# Main entry point into 'elasticsupport' library
#

module Elasticsupport

  #
  # class Elasticsupport
  #
  # scan suppportconfig directory, build class name from file name
  # initialize class instance (does parsing)
  #
  class Elasticsupport
    require 'elasticsearch'

    # constructor
    #
    # opens DB connection
    #
    # @param [String] Directory of unpacked supportconfig data
    #
    def initialize dir
      @client = Elasticsearch::Client.new # log: true
      raise "#{dir.inspect} is not a directory" unless File.directory?(dir)
      @dir = dir
    end

    # index list of file
    #
    # @param [Array] list of files to import from
    #
    def index files
      files.each do |entry|
        next unless entry =~ /^(.*)\.txt$/
        puts "*** #{entry}"
        if $1 == "supportconfig"
          raise "Please remove 'supportconfig.txt from list of files to index"
        end
        # convert filename to class name
        # foo.bar -> foo_bar
        # foo-bar -> FooBar
        klassname = $1.tr(".", "_").split("-").map{|s| s.capitalize}.join("")
        begin
          klass = ::Elasticsupport.const_get(klassname)
          next unless klass.to_s =~ /Elasticsupport/ # ensure Module 'Elasticsupport'
          # create instance (parses file, writes to DB)
          klass.new @client, @dir, entry
#        rescue NameError => e
#          STDERR.puts "#{e}\n\t#{entry} - not implemented"
        rescue Faraday::ConnectionFailed
          STDERR.puts "Elasticsearch DB not running"
        end
      end
    end
  end

end # module Elasticsupport
