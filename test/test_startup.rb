require File.join(File.dirname(__FILE__), 'helper')

class Startup_test < Test::Unit::TestCase

  def test_startup
    # constructor needs 1 argument
#    assert_raise ArgumentError Elasticsupport::Elasticsupport.new
    assert_raise ArgumentError do
      Elasticsupport::Elasticsupport.new
    end
  end

end
