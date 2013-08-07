class CompilationJob
  @queue = :latex

  def self.perform(tex_url)
    puts tex_url
  end
end