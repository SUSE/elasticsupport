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

class Supportconfig
  def initialize client, dir, fname
    @client = client
    @fname = fname
    parse File.join(dir, fname)
  end
private
  #
  # generic parser for supportconfig .txt files
  #
  def parse file
    File.open(file) do |f|
      content = []
      section = nil
      f.each do |l|
        if l =~ /#==\[ (.*) \]===/
          if section
            # old section present
            self.send section, content
            section = nil
            content = []
          end
          section = $1.downcase.tr(" ", "_")
        else
          content << l
        end
      end
      self.send section, content if section
    end
  end
  
  def command content
  end
  
  def system content
  end
  
  def configuration_file content
  end
  
  def verification content
  end
  
  def firewall_services content
  end
end

class BasicEnvironment < Supportconfig
end


class Elasticsupport
  require 'elasticsearch'


  def initialize dir
    @client = Elasticsearch::Client.new log: true
    raise "#{dir.inspect} is not a directory" unless File.directory?(dir)
    @dir = dir
  end
  
  def index!
    Dir.foreach(@dir) do |entry|
      next unless entry =~ /^(.*)\.txt$/
      # foo.bar -> foo_bar
      # foo-bar -> FooBar
      klassname = $1.tr(".", "_").split("-").map{|s| s.capitalize}.join("")
      next unless klassname == "BasicEnvironment"
      puts klassname
      begin
        Kernel.const_get("Supportconfig::#{klassname}").new @client, @dir, entry
      rescue NameError => e
        STDERR.puts "#{e}\n\t#{entry} - not implemented"
      end  
    end
  end
# p client.index index: 'myindex', type: 'mytype', id: 'custom', body: { title: "Indexing from my client" }
end

end

#
# ---- main ----
#

dir = ARGV.shift

elasticsupport = Supportconfig::Elasticsupport.new dir
elasticsupport.index!