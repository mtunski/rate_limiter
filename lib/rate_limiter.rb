require 'rate_limiter/data_store'

class RateLimiter
  def initialize(app, options = {}, &config)
    @app        = app
    @limit      = options['limit']    || 60
    @reset_in   = options['reset_in'] || 3600
    @data_store = options['store']    || DataStore.new
    @config     = config
    @client     = nil
  end

  def call(env)
    if config_provided?
      if (token = token(env))
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
    setup_client unless client_registered?(client_id)
    @data_store.set(client_id, @client)

    reset_limit               if should_reset?
    return limit_hit_response if limit_hit?
    decrease_remaining

    status, headers, response = @app.call(env)

    headers['X-RateLimit-Limit']     = @limit.to_s
    headers['X-RateLimit-Remaining'] = @client['remaining'].to_s
    headers['X-RateLimit-Reset']     = @client['reset_at'].to_s

    [status, headers, response]
  end

  private

  def config_provided?
    !!@config
  end

  def token(env)
    @config.call(env)
  end

  def decrease_remaining
    @client['remaining'] -= 1
  end

  def setup_client
    @client              = {}
    @client['remaining'] = @limit
    @client['reset_at']  = (Time.now + @reset_in).to_i
  end

  def client_registered?(client_id)
    !!@data_store.get(client_id)
  end

  def limit_hit?
    @client['remaining'] == 0
  end

  def limit_hit_response
    [429, {}, 'Too many requests']
  end

  def should_reset?
    reset_at = @client['reset_at']

    reset_at && (reset_at <= Time.now.to_i)
  end

  def reset_limit
    @client['reset_at']  = (Time.now + @reset_in).to_i
    @client['remaining'] = @limit
  end
end
