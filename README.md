### Redis Health is a simple monitoring tool for Redis that notifies when abnormal things are happening in Redis.

Install:
    gem install 'redis-health'

Use:
    require 'redis'
    require 'redis_health'
    require 'pony'

    RedisHealth.configure do
      watch('worker count fell below 2 for more then 1 minute') do
        v = redis.scard('resque:party:workers')
        {triggered: v < 2, value: v}
      end

      watch('redis connected client count fell below 3 for more then 30 seconds', 30) do
        client_count = redis.info['connected_clients'].to_i
        {triggered: client_count < 3, value: client_count}
      end

      watch('HOLY **** TEH FAIL LOGZ IZ HUGE', 1) do
        v = redis.llen('resque:party:failed')
        {triggered: v > 1000, value: v}
      end

      notify do |notices|
        #TEXT EMAIL FAX POSTCARD TWEET GOES HERE
        Pony.mail(:to => 'steve@hypermegaglobacorp.web', :from => 'failbot@hypermegaglobacorp.web', :html_body => '<h1>Some stuff seems to have failed, take a look pretty please</h1> ' + notices.join(', '))
      end
    end

    redis = Redis.new

    #runs watches and sleeps for 1 second in a loop
    RedisHealth.new(redis).run

It calls your notifier block if a watch has been triggered for the specified number of seconds, passing it a list of triggered messages such as:

    ['HOLY **** TEH FAIL LOGZ IZ HUGE, value is now 100000', 'worker count fell below 2 for more then 1 minute, value is now 0']

And calls it again if a watch ceases to trigger, with a list of triggered messages such as:

    ['HOLY **** TEH FAIL LOGZ IZ HUGE no longer in effect, value is 10', 'worker count fell below 2 for more then 1 minute no longer in effect, value is now 100000']
