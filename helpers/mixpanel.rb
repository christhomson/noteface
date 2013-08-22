module Helpers
  module Mixpanel
    def track_event(user, event, params)
      if not authorized?
        @mixpanel_tracker.track("#{user[:ip]} (#{user[:user_agent]})", event, params)
      end
    end
  end
end