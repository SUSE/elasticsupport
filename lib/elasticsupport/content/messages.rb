#encoding: utf-8
#
# Import supportconfig's
#   messages.txt
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

    class Messages < Supportconfig

      def command content
        case content.shift
        when /\/var\/log\/warn/
#          @elasticsupport.logstash.
        when /\/var\/log\/messages/
        when /\/var\/log\/localmessages/
        end
      end
    end

  end # module
end # module
