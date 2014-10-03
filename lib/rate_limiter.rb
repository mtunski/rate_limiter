require 'rate_limiter/version'

class RateLimiter
  def initialize(app, options={})
    @app     = app
    @options = options
    @options['limit'] ||= 60
    @remaining = @options['limit']
  end

  def call(env)
    status, headers, response = @app.call(env)

    headers['X-RateLimit-Limit']     = @options['limit']
    headers['X-RateLimit-Remaining'] = (@remaining -= 1)

    [status, headers, response]
  end
end
