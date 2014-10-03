require 'test_helper'
require 'rate_limiter'

class RateLimiterTest < Minitest::Test
  include Rack::Test::Methods

  def app
    app     = lambda { |env| [200, {}, 'App'] }
    options = { 'limit' => 30 }

    RateLimiter.new(app, options)
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
  end

  def test_middleware_handles_options_param_with_limit_value
    get '/'

    assert_equal 30, last_response.headers['X-RateLimit-Limit']
  end
end
