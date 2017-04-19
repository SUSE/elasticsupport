#encoding: utf-8
#
# Import supportconfig's
#   supportconfig.txt
# into elasticsearch
#
# Copyright (c) 2016 SUSE LINUX GmbH
# Written by Klaus Kämpf <kkaempf@suse.de>
#
# See MIT-LICENSE at toplevel for license information
#

require 'supportconfig'

module Elasticsupport

  module Content
    # supportconfig.txt

    class Supportconfig < Elasticsupport::Supportconfig
      def _mappings
        {
          supportconfig: {
            request:    { type: 'string', index: 'not_analyzed' },
            sc_date:    { type: 'date', index: 'not_analyzed' },
            sc_version: { type: 'string', index: 'not_analyzed' }
          }
        }
      end
      def verification content
        content.each do |l|
          case l
          when /Data Directory:\s+(.*)/
            self.name = File.basename($1)
          when /Script Version:\s+(.*)/
            @version = $1
          when /Script Date:\s+(\d{4})\s(\d{1,2})\s(\d{1,2})/
            @date = Date.new($1.to_i,$2.to_i,$3.to_i)
            #   Command with Args: /sbin/supportconfig -ur 101054071681
          when /Command with Args: \/sbin\/supportconfig -ur (.*)/
            @supportrequest = $1
          end
        end
        _write 'supportconfig', { request: @supportrequest, sc_version: @version, sc_date: @date }
      end
    end
  end # module

end # module
