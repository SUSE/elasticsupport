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
    def command content
      content.shift # drop rpm command
      unless content.shift =~ /NAME.*VERSION.*RELEASE/ # ensure header
        return
      end
      
      # parse
      # NAME                                DISTRIBUTION                        VERSION
      content.each do |l|
        next if l[0,1] == "#"
        l =~ /([^\s]+)\s+(.*)\s+([^\s]+)/
        _write 'rpm', { name: $1, distribution: $2, version: $3 }
      end
    end
    def close
    end
  end

end # module
