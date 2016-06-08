#
# Import a supportconfig into elasticsearch
#
# Index    (Database) Elasticsupport
# Type     (Table)    rpm
# Id
# Document (Row)      package name
# Field    (Column)   nevra

require 'elasticsupport'

module Elasticsupport

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

end # module Supportconfig
