module Helpers
  module Authentication
   def protected!
      return if authorized?
      headers['WWW-Authenticate'] = 'Basic realm="Go away"'
      halt 401, "Sorry, you aren't authorized to view that.\n"
    end

    def authorized?
      user = @config["auth"]["username"]
      pass = @config["auth"]["password"]
      @auth ||= Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [user, pass]
    end
  end
end
