require 'rate_limiter/version'

class RateLimiter
  def initialize(app, options={})
    @app     = app
    @options = options
    @options['limit'] ||= 60
  end

  def call(env)
    status, headers, response = @app.call(env)

    headers['X-RateLimit-Limit'] = @options['limit']

    [status, headers, response]
  end
end
