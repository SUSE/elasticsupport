#
# Import a supportconfig into elasticsearch
#
# Index    (Database) Elasticsupport
# Type     (Table)    rpm
# Id
# Document (Row)      package name
# Field    (Column)   nevra

require 'supportconfig'

module Elasticsupport

  class Rpm < Supportconfig
#    def _mappings
#      { rpm: {
#          rpmname: { type: 'string', analyzer: 'no_analyzer' },
#          rpmversion: { type: 'string', analyzer: 'no_analyzer' }
#        }
#      }
#    end

    def command content
      unless content.shift =~ /\# rpm -qa --queryformat.*NAME.*VERSION.*RELEASE/ # ensure header
        return
      end
      puts "rpm !"
      content.shift # drop rpm command
      
      # parse
      # NAME                                DISTRIBUTION                        VERSION
      content.each do |l|
        next if l[0,1] == "#"
        l =~ /([^\s]+)\s+(.*)\s+([^\s]+)/
        _write :rpm, { rpmname: $1, rpmdistribution: $2, rpmversion: $3 }
      end
    end
    def close
    end
  end

end # module
