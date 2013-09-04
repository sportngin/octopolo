# Trap interrupts (e.g., Ctrl-C) to quit cleanly, without a stack trace.
# -- lifted from vagrant's source
Signal.trap("INT") do
  puts ""
  puts "Exiting..."
  exit 1
end

# Public: Require the module, if it is installed
#
# Only intended for modules which it is OK to skip, as they aren't universally needed.
#
# module_name - String of the module to `require`
#
# Returns result of require, or nil if a LoadError occurs.
def require_if_installed module_name
  require module_name
rescue LoadError
  # do nothing
end

require "readline"
require "octokit"
require "hashie"
require_if_installed "engineyard"
require_if_installed "cloud_ngin"
require "automation/cli"
require "automation/config"
require "automation/convenience_wrappers"

module Automation
  # Your code goes here...
end
