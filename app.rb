require 'yaml'
require './workers/compilation_job'
require './helpers/authentication'

class Noteface < Sinatra::Base
  before do
    @config ||= YAML.load_file('config.yml')
    @redis ||= Redis.new # assume localhost:6379
    Resque.redis = @redis
  end

  helpers Sinatra::JSON
  helpers Helpers::Authentication
  helpers do

    def serve_pdf(document_name, sha)
      if sha
        user_info = {
          :ip => request.ip,
          :user_agent => request.user_agent,
          :time => Time.now.to_i
        }
        @redis.sadd "#{document_name}:#{sha}:downloads", user_info.to_json
        user_info[:sha] = sha
        @redis.sadd "#{document_name}:downloads", user_info.to_json

        headers \
          'Content-Type' => 'application/pdf',
          'Etag' => sha

        File.read("./documents/#{document_name}/#{sha}/#{document_name}.pdf")
      else
        404
      end
    end
  end

  post '/receive_push/:secret' do
    halt 403 if params[:secret] != @config["github"]["post_receive_secret"]
    payload = JSON.parse params[:payload]
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
      Resque.enqueue(CompilationJob, file, payload["head_commit"], payload["repository"])
    end

    201
  end

  get '/dl/latest/:document_name.pdf' do
    document_name = params[:document_name]
    latest_sha = @redis.get("#{document_name}:latest")

    serve_pdf params[:document_name], latest_sha
  end

  get '/dl/:sha/:document_name.pdf' do
    serve_pdf params[:document_name], params[:sha]
  end

  get '/documents.json' do
    document_names = @redis.smembers('documents')
    documents = []

    if document_names
      for document_name in document_names
        latest_sha = @redis.get("#{document_name}:latest")
        last_modified = @redis.get("#{latest_sha}:timestamp")

        documents << {
          :name => document_name,
          :sha => latest_sha,
          :timestamp => last_modified
        }
      end
    end

    json documents
  end

  # TODO - dashboard for viewing documents and stats
  get '/dash' do
    protected!
    200
  end
end