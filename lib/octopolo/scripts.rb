require_relative "git"

module Octopolo
  module Scripts
    module Base
      def self.included(klass)
        class << klass
          attr_accessor :config
          attr_accessor :cli
        end

        klass.config = Octopolo.config
        klass.cli = Octopolo::CLI
      end
    end
  end
end

# Mostly used for tests
unless defined?(GLI)
  require 'gli'
  include GLI::App
end
