ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'

Bundler.require :default
require File.expand_path '../../app.rb', __FILE__
