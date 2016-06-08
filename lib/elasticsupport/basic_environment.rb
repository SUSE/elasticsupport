#
# Import a supportconfig into elasticsearch
#
# Index    (Database) Elasticsupport
# Type     (Table)    rpm
# Id
# Document (Row)      package name
# Field    (Column)   nevra

module Elasticsupport

  # basic_environment.txt

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

end # module Supportconfig
