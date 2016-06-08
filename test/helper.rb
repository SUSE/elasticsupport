$: << File.join(File.dirname(__FILE__), "..", "lib")
require 'test/unit'
require 'elasticsupport'

if ENV["DEBUG"]
  Elasticsupport::Logging.logger = Logger.new(STDERR)
  Elasticsupport::Logging.logger.level = Logger::DEBUG
end
