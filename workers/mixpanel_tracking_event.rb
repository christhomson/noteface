require 'mixpanel-ruby'
require 'yaml'

class MixpanelTrackingEvent
  @queue = :noteface

  def self.perform(id, user, event, params)
    @config = YAML.load_file("config/settings.yml")

    if @config['mixpanel'] && @config['mixpanel']['token']
      tracker = Mixpanel::Tracker.new(@config['mixpanel']['token'])
      tracker.track(id, event, params)
    else
      throw new Error("Mixpanel is not configured")
    end
  end
end
