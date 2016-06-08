#
# Insert a supportconfig into elasticsearch
# Index    (Database) Elasticsupport
# Type     (Table)    rpm
# Id
# Document (Row)      package name
# Field    (Column)   nevra

def usage(msg=nil)
  STDERR.puts "*** Err: #{msg}" if msg
  STDERR.puts "Usage:"
  STDERR.puts "elasticsupport <dir>"
  STDERR.puts "\t<dir> => unpacked supportconfig tarball"
  exit 1
end

module Supportconfig

  #
  # class Supportconfig
  #   base class
  #
  # contains generic file parser
  #

  class Supportconfig
    def initialize client, dir, fname
      @client = client
      @fname = fname
      parse File.join(dir, fname)
      @date = nil
      @hostname = nil
      @running_kernel = nil
      @arch = nil
    end
private
    #
    # generic parser for supportconfig .txt files
    #
    # .txt files have multiple section, every section
    # is named and starting with
    #   #==[ <name> ]====...
    # following is content until EOF or the next section
    #
    # this parser splits files into sections and assembles
    # the section content as array of lines
    #
    # the section name is used as a callback name
 
    def parse file
      File.open(file) do |f|
        content = []
        section = nil
        f.each do |l|
          l.chomp!
          next if l.empty?
          if l =~ /#==\[ (.*) \]===/
            # new section start
            if section
              # old section present
              self.send section, content
              section = nil
              content = []
            end
            section = $1.downcase.tr(" ", "_")
          elsif section
            content << l
          else
            # skip header
          end
        end
        # send final section
        self.send section, content if section
        self.close
      end
    end
public 
  # section:
  # #==[ Command ]======================================#
  #
  def command content
    # empty - derive from Supportconfig and implement there
  end
  
  # section
  # #==[ System ]=======================================#
  #
  def system content
    # empty - derive from Supportconfig and implement there
  end

  # section
  # #==[ Configuration File ]===========================#
  #
  def configuration_file content
    # empty - derive from Supportconfig and implement there
  end

  #
  # #==[ Verification ]=================================#
  #  
  def verification content
    # empty - derive from Supportconfig and implement there
  end
  
  #
  # #==[ Firewall Services ]============================#
  #
  def firewall_services content
  end
  
  # close file (eof reached)
  def close
    STDERR.puts "#{self.class}.close not implemented !"
  end
end

  #
  #
  #
  class BasicEnvironment < Supportconfig
    def command content
      puts "Command #{content.inspect}"
      case content[0]
      when /\/bin\/date/
        # Mon Apr 11 14:55:27 CDT 2016
        @date = content[1]
      when /\/bin\/uname/
        # Linux usbsusemanager 3.0.101-0.47.71-default #1 SMP Thu Nov 12 12:22:22 UTC 2015 (b5b212e) x86_64 x86_64 x86_64 GNU/Linux
        # 0     1              2                       3  4   5   6   7  8        9   10   11        12     13     14     15
        @uname = content[1]
        unames = @uname.split(" ")
        @hostname = unames[1]
        @running_kernel = unames[2]
        @arch = unames[12]
      else
        puts "??? #{content[0]}"
      end
    end
    
    def close
      @client.index index: 'elasticsupport', type: 'environment', id: "#{@hostname}@#{@date}", body: { uname: @uname }
    end
  end
  
  class Rpm < Supportconfig
    def command content
      unless content[0] =~ /NAME.*VERSION.*RELEASE/
        return
      end
      # NAME                                DISTRIBUTION                        VERSION
      content.each do |l|
        l =~ /([^\s]+)\s+(.*)\s+([^\s]+)/
        name = $1
        distribution = $2
        version = $3
#        puts "#{name}-#{version}\n\t\t#{l}"
#        client.index index: 'elasticsupport', type: 'rpm', body: { name: name, version: version }
      end
    end
  end

  #
  # class Elasticsupport
  #
  # scan suppportconfig directory, build class name from file name
  # initialize class instance (does parsing)
  #
  class Elasticsupport
    require 'elasticsearch'


    def initialize dir
      @client = Elasticsearch::Client.new log: true
      raise "#{dir.inspect} is not a directory" unless File.directory?(dir)
      @dir = dir
    end
  
    def index files
      files.each do |entry|
        next unless entry =~ /^(.*)\.txt$/
        if $1 == "supportconfig"
          raise "Please remove 'supportconfig.txt from list of files to index"
        end
        # foo.bar -> foo_bar
        # foo-bar -> FooBar
        klassname = $1.tr(".", "_").split("-").map{|s| s.capitalize}.join("")
        begin
          klass = ::Supportconfig.const_get(klassname)
          next unless klass.to_s =~ /Supportconfig/ # ensure Module 'Supportconfig'
          # create instance (parses file, writes to DB)
          klass.new @client, @dir, entry
        rescue NameError => e
          STDERR.puts "#{e}\n\t#{entry} - not implemented"
        end  
      end
    end
  end

end # module Supportconfig

#
# ---- main ----
#

dir = ARGV.shift

elasticsupport = Supportconfig::Elasticsupport.new dir
elasticsupport.index [ "basic-environment.txt", "rpm.txt", "hardware.txt" ]
