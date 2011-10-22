require 'redis'

$redis = Redis.new
require 'yaml'

conf = YAML.load(File.open(File.dirname(__FILE__) + '/config.yml'))

#notify when config values are in format of:
#operation key operator value
keys = conf['notify_when']

timer_hash = {}

watchers = keys.collect do |op_hash|
  label_template = op_hash.fetch('label', op_hash['check'])
  check = op_hash.fetch('check', '')
  seconds = op_hash.fetch('seconds', 60)

  redis_op, key, operator, value = check.split(' ')

  -> do
    v = $redis.send(redis_op.downcase, conf['namespace'].to_s + key)
    v = v.count if v.is_a?(Array)
    puts v
    triggered = eval("#{v} #{operator} #{value}")
    label = label_template.gsub('{v}', v.to_s)
    fail_time = timer_hash[label].to_i

    if triggered
      t = timer_hash[label] = fail_time + 1
      label if t == seconds
    end
  end
end

loop do
  puts watchers.collect(&:call)
  sleep 1
end
