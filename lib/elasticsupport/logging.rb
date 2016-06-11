#
# Log helper for elasticsupport
#
# Copyright (c) 2016 SUSE LINUX GmbH
#
# See MIT-LICENSE at toplevel for license information
#
require 'logger'

module Elasticsupport
  module Logging

    def self.logger=(logger)
      @logger = logger
    end

    def self.logger
      @logger ||= Logger.new('/dev/null')
    end

    def logger
      Logging.logger
    end

  end
end
