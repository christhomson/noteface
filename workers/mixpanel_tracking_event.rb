require 'mixpanel-ruby'
require 'yaml'

class MixpanelTrackingEvent
  @queue = :mixpanel

  def self.perform(user, event, params)
    @config = YAML.load_file("config/settings.yml")

    if @config['mixpanel'] && @config['mixpanel']['token']
      tracker = Mixpanel::Tracker.new(@config['mixpanel']['token'])
      tracker.track("#{user['ip']} (#{user['user_agent']})", event, params)
    else
      throw new Error("Mixpanel is not configured")
    end
  end
end