require "automation/cloud_providers/cloud_ngin"
require "automation/cloud_providers/engine_yard"

module CloudProvider
  NoValidProvider = Class.new(StandardError)
end

Capistrano::Configuration.instance(:must_exist).load do
  if defined? CloudNgin
    set(:cloud_provider) { Automation::CloudProvider::CloudNgin.new(fetch(:configurator).cluster, self) }
    set(:server_restart_command) { "/etc/init.d/#{fetch(:application)} restart"}
  elsif defined? EY::API
    set :ey_token, '1958fd57ea90f787805fdba7a31ef3fe' # Luke's api token.. could consider grabbing this from ~/.eyrc, but not everyone may have this?
    set(:cloud_provider) { Automation::CloudProvider::EngineYard.new(fetch(:cloud_env_name), fetch(:ey_token), self) }
    set(:load_balancer_add_command) { "/data/#{fetch(:application)}/shared/bin/haproxy_add" }
    set(:load_balancer_remove_command) { "/data/#{fetch(:application)}/shared/bin/haproxy_remove" }
    set(:server_restart_command) { "/etc/init.d/nginx restart"}
    set(:server_spin_up_command) { "curl 127.0.0.1:81 > /dev/null 2>&1" }
  else
    raise CloudProvider::NoValidProvider, "Application not configured with a cloud provider (CloudNgin or Engine Yard). Unable to continue."
  end
end
