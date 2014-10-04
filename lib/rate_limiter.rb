require 'rate_limiter/version'

class RateLimiter
  def initialize(app, options = {})
    @app      = app
    @options  = options
    @reset_in = (@options['reset_in'] ||= 3600)
    @clients  = {}
  end

  def call(env)
    ip = env['REMOTE_ADDR']

    setup_client(ip)          unless client_registered?(ip)
    reset_limit(ip)           if should_reset?(ip)
    return limit_hit_response if limit_hit?(ip)

    status, headers, response = @app.call(env)

    headers['X-RateLimit-Limit']     = @options['limit']
    headers['X-RateLimit-Remaining'] = (@clients[ip]['remaining'] -= 1)
    headers['X-RateLimit-Reset']     = (@clients[ip]['reset'] ||= (Time.now + @reset_in).to_i)

    [status, headers, response]
  end

  private

  def setup_client(ip)
    @clients[ip]              = {}
    @clients[ip]['remaining'] = @options['limit']
  end

  def client_registered?(ip)
    @clients.has_key?(ip)
  end

  def limit_hit?(ip)
    @clients[ip]['remaining'] == 0
  end

  def limit_hit_response
    return [429, {}, 'Too many requests']
  end

  def should_reset?(ip)
    @clients[ip]['reset'] && (@clients[ip]['reset'] <= Time.now.to_i)
  end

  def reset_limit(ip)
    @clients[ip]['reset']     = (Time.now + @reset_in).to_i
    @clients[ip]['remaining'] = @options['limit']
  end
end
