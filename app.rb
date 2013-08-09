require 'yaml'
require './workers/compilation_job'

class Noteface < Sinatra::Base
  before do
    @config ||= YAML.load_file('config.yml')
    @redis ||= Redis.new # assume localhost:6379
    Resque.redis = @redis
  end

  helpers do
    def protected!
      return if authorized?
      headers['WWW-Authenticate'] = 'Basic realm="Go away"'
      halt 401, "Sorry, you aren't authorized to view that.\n"
    end

    def authorized?
      user = @config["auth"]["username"]
      pass = @config["auth"]["password"]
      @auth ||= Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == [user, pass]
    end

    def serve_pdf(document_name, sha)
      if sha
        user_info = "#{request.ip},#{Time.now.to_i},#{request.user_agent}"
        @redis.sadd "#{document_name}:#{sha}:downloads", user_info

        headers \
          'Content-Type' => 'application/pdf',
          'Etag' => sha

        File.read(File.join("./documents/#{document_name}/#{sha}/#{document_name}.pdf"))
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
      Resque.enqueue(CompilationJob, file, payload["head_commit"]["id"], payload["repository"])
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

  # TODO - dashboard for viewing documents and stats
  get '/dash' do
    protected!
    200
  end
end