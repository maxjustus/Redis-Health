require './lib/redis_health'

Gem::Specification.new do |s|
  s.name = "redis-health"
  s.author = "Max Justus Spransy"
  s.email = "maxjustus@gmail.com"
  s.homepage = "http://github.com/maxjustus/Redis-Health"
  s.license = 'MIT'
  s.summary = "Knowing is half the battle"
  s.description = "When shit hits the fan in your redis db, Redis Health lets you know before your customers do"
  s.files = Dir["lib/**/*"] + ["README.md"]
  s.version = RedisHealth::VERSION
  s.add_dependency('redis')
  s.add_development_dependency('rspec', '>= 2.6.0')
end
