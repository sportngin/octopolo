require "readline"
require "octokit"
require "hashie"
require_relative "octopolo/cli"
require_relative "octopolo/config"
require_relative "octopolo/version"
require_relative "octopolo/convenience_wrappers"

module Octopolo

  def self.config
    @config ||= Octopolo::Config.parse
  end

  def self.user_config
    @user_config ||= Octopolo::UserConfig.parse
  end

end
