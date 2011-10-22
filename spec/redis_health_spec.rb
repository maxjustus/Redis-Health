require_relative '../lib/redis_health'

describe RedisHealth do
  before do
    RedisHealth.watchers = {}
  end

  context 'initialize' do
    it 'takes a redis instance' do
      r = stub('Redis')
      c = RedisHealth.new(r)
      c.redis.should == r
    end
  end

  context 'triggered_times' do
    it 'returns a hash of triggered times' do
      c = RedisHealth.new(nil)
      c.triggered_times.should == {}
      c.triggered_times['hi'] = 1
      c.triggered_times.should == {'hi' => 1}
    end
  end

  context 'configure' do
    it 'takes a block and executes in the context of the singleton' do
      RedisHealth.should_receive(:watch)
      RedisHealth.configure do
        watch
      end
    end
  end

  context 'execute_watches' do
    it 'returns a collection of notices for watches the user should know about' do
      triggered = 'stuff fell below 5'
      no_longer_triggered = 'job count exceeded 70'
      no_longer_triggered_with_no_value = 'lame threshold exceeded'

      RedisHealth.configure do
        watch(triggered, 5) do
          {triggered: true, value: 1}
        end

        watch(no_longer_triggered, 4) do
          {triggered: false, value: 30}
        end

        watch(no_longer_triggered, 4) do
          {triggered: false, value: 30}
        end

        watch(no_longer_triggered_with_no_value, 4) do
          {triggered: false}
        end

        watch('not triggered', 3) do
          {triggered: true, value: 1}
        end
      end

      h = RedisHealth.new(nil)
      h.triggered_times = {triggered => 5, no_longer_triggered => 400, no_longer_triggered_with_no_value => 5}
      h.execute_watches.should == [
        triggered + ', value is now 1',
        no_longer_triggered + ' is no longer in effect, value is now 30',
        no_longer_triggered_with_no_value + ' is no longer in effect'
      ]
    end

    it 'returns notices for watches which were been triggered the amount of times configured, but are no longer' do
      RedisHealth.configure do
        watch('cool', 3) do
          {triggered: false, value: 1}
        end
      end
      h = RedisHealth.new(nil)
      h.triggered_times = {'cool' => 4}
      h.execute_watches.should == ['cool is no longer in effect, value is now 1']
    end

    it 'returns notices for watches which have been triggered the amount of times configured' do
      RedisHealth.configure do
        watch('cool', 3) do
          {triggered: true, value: 1}
        end
      end
      h = RedisHealth.new(nil)
      h.triggered_times = {'cool' => 3}
      h.execute_watches.should == ['cool, value is now 1']
    end

    it 'does not return notices for watches which have already been trigged the amount of times configured' do
      RedisHealth.configure do
        watch('cool', 3) do
          {triggered: true, value: 1}
        end
      end
      h = RedisHealth.new(nil)
      h.triggered_times = {'cool' => 4}
      h.execute_watches.should == []
    end

    it 'does not return notices for watches which were trigged the amount of times configured, but are no longer' do
      RedisHealth.configure do
        watch('cool', 3) do
          {triggered: false, value: 1}
        end
      end
      h = RedisHealth.new(nil)
      h.triggered_times = {'cool' => 2}
      h.execute_watches.should == []
    end

    it 'increments triggered_time for watchers returning true' do
      triggered = 'cool thing 1'
      untriggered = 'whatever'
      RedisHealth.configure do
        watch(triggered, 4) do
          {triggered: true, value: 44}
        end
        watch(untriggered, 4) do
          {triggered: false, value: 33}
        end
      end
      h = RedisHealth.new(nil)
      h.execute_watches
      h.execute_watches
      h.triggered_times[triggered].should == 2
      h.triggered_times[untriggered].should == 0
    end

    it 'reset triggered_time for watchers previously triggered but now returning false' do
      untriggered = 'whatever'

      RedisHealth.configure do
        watch(untriggered, 4) do
          {triggered: false}
        end
      end
      h = RedisHealth.new(nil)
      h.triggered_times = {untriggered => 55}
      h.execute_watches
      h.triggered_times[untriggered].should == 0
    end
  end

  context '.watch' do
    it 'takes a label, time and block and sets up a watcher' do
      watch_result = stub('Watch result')
      watcher = RedisHealth.watch('lame', 10) do
        watch_result
      end
      RedisHealth.watchers['lame'].should == watcher[1]
    end
  end

  context '.notify' do
    it 'sets notifier lambda on class' do
      message = 'HI MAN'
      RedisHealth.notify do |notices|
        notices.join
      end
      RedisHealth.notifier.call([message]).should == message
    end
  end

  context '#notify' do
    it 'calls notify lambda with watcher notices if notices are not empty' do
      RedisHealth.notify do |notices|
        notices
      end
      h = RedisHealth.new(nil)
      notices = stub('Notices', 'empty?' => false)
      h.should_receive(:execute_watches) {notices}
      h.notify.should == notices
    end

    it 'does not call notify lambda with watcher notices if notices are empty' do
      RedisHealth.notify do |notices|
        raise 'Expected notifier not to be called'
      end
      h = RedisHealth.new(nil)
      notices = stub('Notices', 'empty?' => true)
      h.should_receive(:execute_watches) { notices }
      h.notify.should == nil
    end
  end

  describe '#run' do
    it 'calls notify and sleeps for 1 second in a continuous loop' do
      h = RedisHealth.new(nil)
      h.instance_eval do
        def loop(&blk)
          blk.call
        end
      end

      h.should_receive(:notify)
      h.should_receive(:sleep).with(1)
      h.run
    end
  end
end

#RedisHealth.configure do
#  watch('Workers have gone below 2 for more then 1 minute', 60) do |redis|
#    redis.keys < 2
#  end
#end
