require_relative 'lib/redis_health'

RedisHealth.configure do
  watch('worker count fell below 2 for more then 1 minute') do
    v = redis.scard('resque:socialvolt:workers')
    {triggered: v < 2, value: v}
  end

  watch('redis connected client count fell below 3 for more then 30 seconds', 30) do
    client_count = redis.info['connected_clients'].to_i
    {triggered: client_count < 3, value: client_count}
  end

  watch('HORY **** TEH FAIL LOGZ IZ HUGE', 1) do
    v = redis.llen('resque:socialvolt:failed')
    {triggered: v > 1000, value: v}
  end

  notify do |notices|
    #TEXT EMAIL FAX POSTCARD TWEET GOES HERE
    p notices.join(', ')
  end
end

redis = Redis.new

RedisHealth.new(redis).run
