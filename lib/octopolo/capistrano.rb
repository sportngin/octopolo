require "automation/engine_yard_api"

module Automation
  class Capistrano
    def self.configure_roles(env_name, api_hostname, context)
      instance = new(env_name, api_hostname)
      instance.configure_roles(context)
      instance
    end

    def initialize(cloud_env_name, api_hostname)
      @cloud_env_name = cloud_env_name
      @api_hostname = api_hostname
      @https = true
      @audit_receiver = []
      @migration_instance_set = false
      @token = Automation::EngineYardAPI::API_KEY

      EY.config.instance_variable_get(:@config)["endpoint"] = Automation::EngineYardAPI::API_ENDPOINT
    end

    def configure_roles(context)
      nodes.each do |node|
        roles = roles_for_node(node)
        context.server(node.public_hostname, *roles) unless roles.empty?
      end

      context.set :user, environment.username
      context.set :rack_env, environment.framework_env
      context.set :rails_env, environment.framework_env
      context.set :node_env, environment.framework_env
      context.set :hostname, url
      context.set :cloud_env_name, @cloud_env_name
      context.set :audit_receiver, @audit_receiver
    end

    def nodes
      @nodes ||= environment.instances
    end

    def app_instances
      app_roles = %w(app app_master solo)
      nodes.select { |node| app_roles.include? node.role }
    end

    def environment
      @environment ||= api.environments.named(@cloud_env_name)
    end

    def api
      @api ||= Automation::Config.new.api_object
    end

    def url
      "https://#{@api_hostname}"
    end

    def roles_for_node(node)
      roles = []

      case node.role
      when "util"
        if node.name
          roles << "resque" if node.name.include?("resque")
          roles << "redis" if node.name.include?("redis")
          roles << "memcache" if node.name.include?("memcache")
          roles << "delayed_job" if node.name.include?("delayed_job")
          if !@migration_instance_set && !roles.include?({:no_release => true})
            roles << "db"
            roles << {:primary => true}
            @migration_instance_set = true
          end
        end
        roles << "utility"
      when "app_master", "app", "solo"
        roles << node.role
        roles << "web"
        roles << "app"
        if !@migration_instance_set && %w(app_master solo).include?(node.role)
          roles << "db"
          roles << {:primary => true}
          @migration_instance_set = true
        end
      end

      roles.uniq
    end
  end
end
