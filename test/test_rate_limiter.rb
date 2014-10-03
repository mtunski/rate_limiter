require 'test_helper'

class RateLimiterTest < Minitest::Test
  include Rack::Test::Methods

  def app
    lambda { |env| ['200', {'Content-Type' => 'text/html'}, ['App']] }
  end

  def test_server_responds_successfully
    get '/'

    assert last_response.ok?
  end
end
