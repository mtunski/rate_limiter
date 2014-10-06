require 'rate_limiter/version'

class RateLimiter
  def initialize(app, options = {}, &config)
    @app      = app
    @options  = options
    @reset_in = (@options['reset_in'] ||= 3600)
    @clients  = {}
    @config   = config
  end

  def call(env)
    if config_provided?
      if token = token(env)
        call_with_limit(env, token)
      else
        @app.call(env)
      end
    else
      call_with_limit(env)
    end
  end

  def call_with_limit(env, token = nil)
    client_id = token || env['REMOTE_ADDR']

    setup_client(client_id)   unless client_registered?(client_id)
    reset_limit(client_id)    if should_reset?(client_id)
    return limit_hit_response if limit_hit?(client_id)

    status, headers, response = @app.call(env)

    headers['X-RateLimit-Limit']     = @options['limit']
    headers['X-RateLimit-Remaining'] = (@clients[client_id]['remaining'] -= 1)
    headers['X-RateLimit-Reset']     = (@clients[client_id]['reset'] ||= (Time.now + @reset_in).to_i)

    [status, headers, response]
  end

  private

  def config_provided?
    !@config.nil?
  end

  def token(env)
    @config.call(env)
  end

  def setup_client(client_id)
    @clients[client_id]              = {}
    @clients[client_id]['remaining'] = @options['limit']
  end

  def client_registered?(client_id)
    @clients.has_key?(client_id)
  end

  def limit_hit?(client_id)
    @clients[client_id]['remaining'] == 0
  end

  def limit_hit_response
    return [429, {}, 'Too many requests']
  end

  def should_reset?(client_id)
    @clients[client_id]['reset'] && (@clients[client_id]['reset'] <= Time.now.to_i)
  end

  def reset_limit(client_id)
    @clients[client_id]['reset']     = (Time.now + @reset_in).to_i
    @clients[client_id]['remaining'] = @options['limit']
  end
end
