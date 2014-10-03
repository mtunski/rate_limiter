require 'test_helper'

class RateLimiterTest < Minitest::Test
  include Rack::Test::Methods

  def app
    lambda { |env| [200, {}, 'App'] }
  end

  def test_server_responds_successfully
    get '/'

    assert last_response.ok?
    assert_equal 'App', last_response.body
  end
end
