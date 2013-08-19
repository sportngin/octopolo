# Trap interrupts (e.g., Ctrl-C) to quit cleanly, without a stack trace.
# -- lifted from vagrant's source
Signal.trap("INT") do
  puts ""
  puts "Exiting..."
  exit 1
end

require "readline"
require "octokit"
require "hashie"
require_relative "octopolo/cli"
require_relative "octopolo/config"
require_relative "octopolo/convenience_wrappers"

module Octopolo
  # Your code goes here...
end
