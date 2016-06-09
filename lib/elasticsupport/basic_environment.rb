#
# Import a 'basic-environment.txt' into elasticsearch
#
# Index    (Database) Elasticsupport
# Type     (Table)    rpm
# Id
# Document (Row)      package name
# Field    (Column)   nevra

require 'supportconfig'

module Elasticsupport

  # basic_environment.txt

  class BasicEnvironment < Supportconfig
    def _mappings
      {
        uname: {
          uname: { type: 'string', index: 'not_analyzed' }
        },
        running_kernel: {
          kernel: { type: 'string', index: 'not_analyzed' }
        },
        suse_release: {
          os:          { type: 'string', index: 'not_analyzed' },
          sle_version: { type: 'string', index: 'not_analyzed' },
          version:     { type: 'integer' },
          patchlevel:  { type: 'integer' }
        }
      }
    end
    def command content
      case content[0]
      when /\/bin\/date/
        # Mon Apr 11 14:55:27 CDT 2016
        time = Time.parse(content[1])
        _set :timestamp, time.to_i
      when /\/bin\/uname/
        # Linux usbsusemanager 3.0.101-0.47.71-default #1 SMP Thu Nov 12 12:22:22 UTC 2015 (b5b212e) x86_64 x86_64 x86_64 GNU/Linux
        # 0     1              2                       3  4   5   6   7  8        9   10   11        12     13     14     15
        uname = content[1]
        unames = uname.split(" ")
        _set :hostname, unames[1]
        # write uname after hostname is set
        _write 'uname', { uname: uname }
        running_kernel = unames[2]
        _set :arch, unames[12]
        _write 'running_kernel', { kernel: running_kernel }
      when /\/bin\/rpm/ 
        # /bin/rpm -qa --queryformat "%{DISTRIBUTION}\n" | sort | uniq
      else
        puts "??? #{content[0]}"
      end
    end

    def configuration_file content
      case content[0]
      when /\/etc\/SuSE-release/
        os = content[1]
        if content[2] =~ /VERSION = (\d+)/
          version = $1.to_i
        else
          version = "unknown"
        end
        if content[3] =~ /PATCHLEVEL = (\d+)/
          patchlevel = $1.to_i
        else
          patchlevel = "unknown"
        end
        _write 'suse_release', { os: os, sle_version: "#{version}SP#{patchlevel}", version: version, patchlevel: patchlevel }
      end
      end

    def system content
      # skip
    end

    def verification content
      # skip
    end

    def firewall_services content
      # skip
    end

    def close
    end
  end

end # module
