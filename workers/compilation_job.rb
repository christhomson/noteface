require 'net/https'

class CompilationJob
  @queue = :latex
  @redis = Redis.new

  def self.perform(file, commit, repository)
    @file, @commit, @repository = file, commit, repository
    @sha = @commit["id"]
    log :started

    @redis.set("#{@sha}:timestamp", @commit["timestamp"])

    setup_workspace and fetch and compile
  end


private
  def self.setup_workspace
    log :setup
    directories = [
      "./documents",
      "./documents/#{document_name}",
      "./documents/#{document_name}/#{@sha}"
    ]

    for directory in directories
      Dir.mkdir(directory) unless File.exists?(directory)
    end

    `touch ./documents/#{document_name}/#{@sha}/#{@file}`
  end

  def self.fetch
    log :fetching

    io = open("./documents/#{document_name}/#{@sha}/#{@file}", 'w')
    Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
      http.request_get(uri.path) do |response|
        response.read_body do |chunk|
          io.write(chunk)
        end

        io.close
      end
    end
  end

  def self.compile
    log :compiling

    perform_compilation!

     if $?.to_i.zero?
      log "compile run #1 successful"

      perform_compilation!

      if $?.to_i.zero?
        log "compile run #2 successful"

        @redis.sadd("#{document_name}:compiled_revisions", @sha)
        @redis.set("#{document_name}:latest", @sha)
        @redis.sadd("documents", @file)
        log :done
      else
        log :failed
        puts $?.inspect
      end
     else
      log :failed
      puts $?.inspect
    end
  end

  def self.perform_compilation!
    `cd ./documents/#{document_name}/#{@sha}/; pdflatex #{@file}`
  end

  def self.log(message)
    puts "[compilation #{@repository['name']}/#{@file} @ #{@sha}]: #{message.to_s}"
  end

  def self.document_name
    @document_name ||= @file[0...@file.rindex(/\.tex/)]
  end

  # TODO - for now we assume this job has a SHA that represents the current HEAD of master.
  def self.uri
    @uri ||= URI("https://raw.github.com/#{@repository['owner']['name']}/#{@repository['name']}/master/#{@file}")
  end
end