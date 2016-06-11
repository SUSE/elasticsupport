#encoding: utf-8
#
# Import supportconfig's
#   rpm.txt
# into elasticsearch
#
# Copyright (c) 2016 SUSE LINUX GmbH
# Written by Klaus Kämpf <kkaempf@suse.de>
#
# See MIT-LICENSE at toplevel for license information
#

require 'supportconfig'

module Elasticsupport

  class Rpm < Supportconfig
    def _mappings
      {
        rpm: {
          rpmname:         { type: 'string', index: 'not_analyzed' },
          rpmdistribution: { type: 'string', index: 'not_analyzed' },
          rpmversion:      { type: 'string', index: 'not_analyzed' }
        }
      }
    end

    def command content
      unless content.shift =~ /\# rpm -qa --queryformat.*NAME.*VERSION.*RELEASE/ # ensure header
        return
      end
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
