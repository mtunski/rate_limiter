require 'test_helper'
require 'rate_limiter'

class RateLimiterTest < Minitest::Test
  include Rack::Test::Methods

  def app
    RateLimiter.new(lambda { |env| [200, {}, 'App'] })
  end

  def test_server_responds_successfully
    get '/'

    assert last_response.ok?
    assert_equal 'App', last_response.body
  end

  def test_middleware_adds_desired_header
    get '/'

    headers = last_response.headers

    assert headers.has_key?('X-RateLimit-Limit')
    assert_equal 60, headers['X-RateLimit-Limit']
  end
end
