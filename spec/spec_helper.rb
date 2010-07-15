$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'timeframe'
require 'spec'
require 'spec/autorun'
require 'date'

Spec::Runner.configure do |config|
  
end
