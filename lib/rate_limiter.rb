require 'rate_limiter/version'

class RateLimiter
  def initialize(app, options={})
    @app       = app
    @options   = options
    @remaining = (@options['limit'] ||= 60)
  end

  def call(env)
    return [429, {}, 'Too many requests'] if @remaining == 0

    status, headers, response = @app.call(env)

    headers['X-RateLimit-Limit']     = @options['limit']
    headers['X-RateLimit-Remaining'] = (@remaining -= 1)

    [status, headers, response]
  end
end
