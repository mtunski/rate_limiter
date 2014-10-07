require 'test_helper'
require 'rack/test'
require 'timecop'

require 'rate_limiter'

class RateLimiterTest < Minitest::Test
  include Rack::Test::Methods

  def app
    store   = DataStore.new
    app     = lambda { |env| [200, {'Test-Header' => 'I have received a request!'}, 'App'] }
    options = { 'limit' => 30, 'reset_in' => 2 * 60 * 60, 'store' => store }

    RateLimiter.new(app, options, &@config)
  end

  def test_server_responds_successfully
    get '/'

    assert last_response.ok?
    assert_equal 'App', last_response.body
  end

  def test_middleware_adds_ratelimit_limit_header
    get '/'

    assert last_response.headers.has_key?('X-RateLimit-Limit')
  end

  def test_middleware_handles_options_param_with_limit_value
    get '/'

    assert_equal 30, last_response.headers['X-RateLimit-Limit'].to_i
  end

  def test_middleware_adds_ratelimit_remaining_header
    get '/'

    assert last_response.headers.has_key?('X-RateLimit-Remaining')
  end

  def test_middleware_handles_decreasing_the_number_of_remaining_requests
    get '/'

    assert_equal 29, last_response.headers['X-RateLimit-Remaining'].to_i

    4.times { get('/') }

    assert_equal 25, last_response.headers['X-RateLimit-Remaining'].to_i
  end

  def test_middleware_handles_limiting_number_of_requests
    30.times { get('/') }

    assert_equal 0, last_response.headers['X-RateLimit-Remaining'].to_i
    assert last_response.headers.has_key?('Test-Header')

    get('/')

    assert_equal                 429, last_response.status
    assert_equal 'Too many requests', last_response.body
    refute last_response.headers.has_key?('Test-Header')
  end

  def test_middleware_adds_ratelimit_reset_header
    get '/'

    assert last_response.headers.has_key?('X-RateLimit-Reset')
    assert_in_delta (Time.now + 2 * 60 * 60).to_i, last_response.headers['X-RateLimit-Reset'].to_i, 5
  end

  def test_middleware_handles_resetting_the_limit_of_remaining_requests_and_time_for_next_reset
    5.times { get('/') }

    assert_equal 25, last_response.headers['X-RateLimit-Remaining'].to_i

    Timecop.freeze(Time.now + 2 * 61 * 60) do
      get('/')

      assert_equal 29, last_response.headers['X-RateLimit-Remaining'].to_i
      assert_in_delta (Time.now + 2 * 60 * 60).to_i, last_response.headers['X-RateLimit-Reset'].to_i, 5
    end
  end

  def test_middleware_separates_limit_for_each_client
    5.times { get '/', {}, 'REMOTE_ADDR' => '10.0.0.1' }

    assert_equal 25, last_response.headers['X-RateLimit-Remaining'].to_i

    10.times { get '/', {}, 'REMOTE_ADDR' => '10.0.0.2' }

    assert_equal 20, last_response.headers['X-RateLimit-Remaining'].to_i
  end

  def test_middleware_handles_configuration_block
    @config = lambda { |env| Rack::Request.new(env).params["api_token"] }

    25.times { get '/', { 'api_token' => 12345 } }

    assert_equal 5, last_response.headers['X-RateLimit-Remaining'].to_i

    5.times { get '/', { 'api_token' => 54321 } }

    assert_equal 25, last_response.headers['X-RateLimit-Remaining'].to_i

    60.times { get '/', {} }

    assert last_response.ok?
  end
end
