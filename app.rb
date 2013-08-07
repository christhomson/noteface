require 'yaml'

class Noteface < Sinatra::Base
  before do
    @config ||= YAML.load_file('config.yml')
    @redis ||= Redis.new :host => @config["redis"]["host"], :port => @config["redis"]["port"]
  end
end