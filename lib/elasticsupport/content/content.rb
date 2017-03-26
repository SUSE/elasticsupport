#encoding: utf-8
#
# Track imported content
#
# Copyright (c) 2016 SUSE LINUX GmbH
# Written by Klaus Kämpf <kkaempf@suse.de>
#
# See MIT-LICENSE at toplevel for license information
#

require 'supportconfig'

module Elasticsupport

  module Content

    class Content < Elasticsupport::Supportconfig
      def _mappings
        {
          content: {
            files: { type: 'string', index: 'not_analyzed' }
          }
        }
      end
    end

  end # module

end # module
