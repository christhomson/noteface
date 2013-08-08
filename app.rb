require 'yaml'
require './workers/compilation_job'

class Noteface < Sinatra::Base
  before do
    @config ||= YAML.load_file('config.yml')
    @redis ||= Redis.new # assume localhost:6379
    Resque.redis = @redis
  end

  post '/receive_push/:secret' do
    halt 403 if params[:secret] != @config["github"]["post_receive_secret"]
    payload = JSON.parse request.body.read
    halt 304 if payload["ref"] != "refs/heads/master" # only build on master

    files_to_compile = []
    for commit in payload["commits"]
      files_to_compile << [commit["added"], commit["modified"]]
    end

    files_to_compile.flatten!
    files_to_compile.uniq!
    files_to_compile.select! { |f| f[-4..-1] == ".tex" }

    for file in files_to_compile
      puts "Queuing #{file}@#{payload["after"]} for compilation."
      Resque.enqueue(CompilationJob, file, payload["head_commit"]["id"], payload["repository"])
    end

    201
  end
end