require 'test_helper'

class Rails::Pretty::Logger::Test < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, Rails::Pretty::Logger
  end
end
