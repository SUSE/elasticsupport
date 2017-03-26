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

    # Sets Elasticsupport::Supportconfig#name

    class Supportconfig < Elasticsupport::Supportconfig
      def verification content
        content.each do |l|
          next unless l =~ /Data Directory:\s+(.*)/
          self.name = File.basename($1)
          break
        end
      end
    end
  end # module

end # module
