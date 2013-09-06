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
require "octopolo/cli"
require "octopolo/config"
require "octopolo/convenience_wrappers"

module Octopolo
  # Your code goes here...
end
