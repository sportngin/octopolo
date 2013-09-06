require "pivotal-tracker" # this is the gem we're currently using
require "octopolo/scripts/pivotal_auth"

module Octopolo
  module Pivotal
    # NOTE Should probably extract out to
    class Client
      include UserConfigWrapper
      # Public: Initialize a new instance of Pivotal::Client wrapper class
      def initialize
        # no idea why this is off by default (as of 2013-04-18)
        ::PivotalTracker::Client.use_ssl = true
        begin
          ::PivotalTracker::Client.token = user_config.pivotal_token
        rescue UserConfig::MissingPivotalAuth
          Scripts::PivotalAuth.run
          ::PivotalTracker::Client.token = UserConfig.parse.pivotal_token
        end
      end

      # Public: Fetch an API token for the given authentication
      #
      # email - a String containing the email address used to log in
      # password - a String containing the password
      #
      # Returns a String or raises BadCredentials
      def self.fetch_token(email, password)
        ::PivotalTracker::Client.token(email, password)
      rescue RestClient::Unauthorized
        raise BadCredentials, "No token received from Pivotal Tracker. Please check your credentials and try again."
      end

      def find_story(story_id)
        @projects = PivotalTracker::Project.all
        @projects.map{ |project| project.stories.find(story_id) }.compact.first || raise(StoryNotFound, "No Story was found with that ID in your Projects")
      end
    end

    # the credentials that you've entered are wrong
    BadCredentials = Class.new(StandardError)
    # 404 from the PT api
    StoryNotFound = Class.new(StandardError)
  end
end
