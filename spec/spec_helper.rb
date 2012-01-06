require 'rubygems'
require 'bundler'
Bundler.setup
require 'minitest/spec'
require 'minitest/autorun'
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require File.expand_path('../../lib/timeframe.rb', __FILE__)
require File.expand_path('../../lib/timeframe/core_ext/array.rb', __FILE__)
