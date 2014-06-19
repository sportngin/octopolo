require "clamp"
require_relative "git"

module Octopolo
  module Scripts
    module Base
      def self.included(klass)
        class << klass
          attr_accessor :config
          attr_accessor :cli
        end

        klass.config = Octopolo::Config.parse
        klass.cli = Octopolo::CLI
      end
    end
  end
end

