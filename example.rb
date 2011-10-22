require_relative 'lib/redis_health'

RedisHealth.configure do
  watch('worker count fell below 2 for more then 1 minute', 60) do |redis|
    v = redis.scard('resque:socialvolt:workers')
    {triggered: v < 2, value: v}
  end

  notify do |notices|
    p notices.join(', ')
  end
end

redis = Redis.new

RedisHealth.new(redis).run
