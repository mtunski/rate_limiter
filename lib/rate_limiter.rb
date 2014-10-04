require 'rate_limiter/version'

class RateLimiter
  def initialize(app, options = {})
    @app       = app
    @options   = options
    @remaining = (@options['limit']    ||= 60)
    @reset_in  = (@options['reset_in'] ||= 3600)
  end

  def call(env)
    reset_limit               if should_reset?
    return limit_hit_response if limit_hit?

    status, headers, response = @app.call(env)

    headers['X-RateLimit-Limit']     = @options['limit']
    headers['X-RateLimit-Remaining'] = (@remaining -= 1)
    headers['X-RateLimit-Reset']     = (@reset ||= (Time.now + @reset_in).to_i)

    [status, headers, response]
  end

  private

  def limit_hit?
    @remaining == 0
  end

  def limit_hit_response
    return [429, {}, 'Too many requests']
  end

  def should_reset?
    @reset && (@reset <= Time.now.to_i)
  end

  def reset_limit
    @reset     = (Time.now + @reset_in).to_i
    @remaining = @options['limit']
  end
end
