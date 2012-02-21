# must be included before rubygems or bundler
if ENV['TIMEFRAME_HOME_RUN'] == 'true'
  require 'home_run'
end

require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs.push 'lib'
  t.test_files = FileList['spec/**/*spec.rb']
  t.verbose = true
end


task :default => :test

require 'yard'
YARD::Rake::YardocTask.new
