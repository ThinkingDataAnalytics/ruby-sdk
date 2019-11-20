require File.join(File.dirname(__FILE__), 'lib/thinkingdata-ruby/version.rb')

spec = Gem::Specification.new do |spec|
  spec.name = 'thinkingdata-ruby'
  spec.version = TDAnalytics::VERSION
  spec.files = Dir.glob(`git ls-files`.split("\n"))
  spec.require_paths = ['lib']
  spec.summary = 'Official ThinkingData Analytics API for ruby'
  spec.description = 'The official ThinkingData Analytics API for ruby'
  spec.authors = [ 'ThinkingData' ]
  spec.email = 'sdk@thinkingdata.cn'
  spec.homepage = 'https://github.com/ThinkingDataAnalytics/ruby-sdk'
  spec.license = 'Apache-2.0'

  spec.required_ruby_version = '>= 2.0.0'
end
