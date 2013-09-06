module Octopolo
  module GitHub
    class User
      @cache ||= {}

      attr_accessor :login

      # Public: Instantiate a new User
      #
      # login - The login (username) of the given user
      def initialize login
        self.login = login
      end

      # Public: The real name of the author
      #
      # If the user has a name in GitHub, #author_name returns this. Otherwise
      # returns the given login.
      #
      # Returns a String containing the name
      def author_name
        user_data.name || login
      end

      # Private: The raw GitHub API data for the user
      #
      # Returns a Hashie::Mash containing the data
      def user_data
        User.user_data login
      end

      # Private: The raw GitHub API data for the given login
      #
      # Returns a Hashie::Mash containing the data
      def self.user_data login
        @cache[login] ||= GitHub.user login
      end
    end
  end
end
