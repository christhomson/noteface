require 'net/https'
require 'time'
require 'yaml'

class CompilationJob
  @queue = :latex
  @redis = Redis.new
  MAX_RUNS = 3

  def self.perform(file, commit, repository)
    @file, @commit, @repository = file, commit, repository
    @sha = @commit["id"]
    @config = YAML.load_file("config/settings.yml")
    log :started

    @redis.set("#{@sha}:timestamp", @commit["timestamp"])

    setup_workspace
    fetch
    find_metadata
    compile
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

  def self.find_metadata
    # Let's Look for \title{...} line in the .tex file. So dirty.
    log :metadata
    full_title = `cat ./documents/#{document_name}/#{@sha}/#{@file} | grep "title{"`.strip.split('{').last.gsub(/\}/, '')
    title_components = full_title.split(':')

    @redis.set("#{document_name}:course:code", title_components.first.strip)
    @redis.set("#{document_name}:course:name", title_components.last.strip)
  end

  def self.compile
    log :compiling

    if perform_compilation!
      @redis.sadd("#{document_name}:compiled_revisions", @sha)
      @redis.set("#{document_name}:latest", @sha)
      @redis.sadd("documents", document_name)
      log :done
    else
      log :failed
      puts $?.inspect
    end
  end

  def self.perform_compilation!(run = 1)
    if run <= MAX_RUNS
      time = Time.parse(@commit["timestamp"]).strftime("%B %e, %Y at %l:%M %p")

      output = `cd ./documents/#{document_name}/#{@sha}/;
    #{@config["latex"]["executable"]} "\\def\\sha{#{@sha[0...7]}} \\def\\commitDateTime{#{time}} \\input{#{@file}}"`

      if $?.to_i.zero?
        log "compile run ##{run} successful"
        perform_compilation!(run + 1) if run < MAX_RUNS # if output.include? "Rerun"
        true
      else
        log "compile run ##{run} failed"
        false
      end
    else
      log "max compile runs exceeded"
      false
    end
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
