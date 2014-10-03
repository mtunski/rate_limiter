require 'test_helper'
require 'rate_limiter'

class RateLimiterTest < Minitest::Test
  include Rack::Test::Methods

  def setup
    get '/'
  end

  def app
    app     = lambda { |env| [200, {}, 'App'] }
    options = { 'limit' => 30 }

    RateLimiter.new(app, options)
  end

  def test_server_responds_successfully
    assert last_response.ok?
    assert_equal 'App', last_response.body
  end

  def test_middleware_adds_ratelimit_limit_header
    assert last_response.headers.has_key?('X-RateLimit-Limit')
  end

  def test_middleware_handles_options_param_with_limit_value
    assert_equal 30, last_response.headers['X-RateLimit-Limit']
  end

  def test_middleware_adds_ratelimit_remaining_header
    assert last_response.headers.has_key?('X-RateLimit-Remaining')
  end

  def test_middleware_handles_decreasing_the_number_of_remaining_requests
    assert_equal 29, last_response.headers['X-RateLimit-Remaining']

    4.times { get('/') }

    assert_equal 25, last_response.headers['X-RateLimit-Remaining']
  end
end
