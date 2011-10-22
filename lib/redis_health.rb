class RedisHealth
  VERSION = '0.0.1'
  attr_accessor :redis, :triggered_times
  @watchers = {}

  class << self
    attr_accessor :watchers, :notifier

    def configure(&blk)
      instance_eval(&blk)
    end

    def watch(label, time = 60, &blk)
      w = {
        :time => time,
        :matcher => blk
      }
      watchers[label] = w
      [label, w]
    end

    def notify(&blk)
      @notifier = blk
    end
  end

  def initialize(redis)
    @redis = redis
    @triggered_times = {}
  end

  def execute_watches
    self.class.watchers.collect do |watcher_array|
      label, watcher_hash = watcher_array
      triggered_times[label] ||= 0

      matcher_result = self.instance_eval(&watcher_hash[:matcher])#.call(@redis)
      triggered = matcher_result[:triggered]
      value = matcher_result[:value]
      notice = append_label_value(label, value, triggered)
      times_was = triggered_times[label]

      if triggered
        triggered_times[label] += 1
        if times_was == watcher_hash[:time]
          notice
        end
      else
        triggered_times[label] = 0
        if times_was > 0 && times_was >= watcher_hash[:time]
          notice
        else
          nil
        end
      end
    end.compact
  end

  def notify
    notices = execute_watches
    self.class.notifier.call(notices) unless notices.empty?
  end

  def run
    loop do
      notify
      sleep 1
    end
  end

  private

  def append_label_value(label, v, triggered)
    notice = label
    notice += ' is no longer in effect' unless triggered
    notice += ", value is now #{v}" if v
    notice
  end
end

