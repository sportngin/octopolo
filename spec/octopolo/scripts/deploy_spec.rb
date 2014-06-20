require "spec_helper"
require "octopolo/scripts/deploy"

module Octopolo
  module Scripts
    describe Deploy do
      let(:runner) { Deploy.new '' }
      let(:cli) { stub(:CLI) }
      let(:config) { stub(:config) }

      before do
        runner.cli = cli
        runner.config = config
      end

      context "#parse" do
        let(:environment) { "foo" }
        let(:deploy_method) { "bar"}

        it "does not set environment or deploy method if given no params" do
          runner.parse([])
          runner.environment.should be_nil
          runner.deploy_method.should be_nil
        end

        it "sets the first parameter to environment" do
          runner.parse([environment])
          runner.environment.should == environment
          runner.deploy_method.should be_nil
        end

        it "sets the second parameter to deploy method" do
          runner.parse([environment, deploy_method])
          runner.environment.should == environment
          runner.deploy_method.should == deploy_method
        end
      end

      context "#execute" do
        it "asks the method and environment to deploy to" do
          runner.should_receive(:ask_environment)
          runner.should_receive(:ask_method)
          runner.should_receive(:deploy)

          runner.execute
        end
      end

      context "#ask_environment" do
        let(:environments) { %w(env1, env2) }
        let(:selected_environment) { environments.first }

        before do
          config.stub(deploy_environments: environments)
          config.stub(app_name: "fooapp")
        end

        it "asks which environment to deploy to" do
          cli.should_receive(:ask).with("Which #{config.app_name} environment do you want to deploy to?", config.deploy_environments) { selected_environment }
          runner.ask_environment
          runner.environment.should == selected_environment
        end

        it "does not ask if already set" do
          runner.environment = selected_environment
          cli.should_not_receive(:ask)
          runner.ask_environment
        end
      end

      context "#ask_method" do
        let(:methods) { %w(method1 method2) }
        let(:selected_method) { methods.first }

        before do
          config.stub(deploy_methods: methods)
          runner.environment = "foo"
        end

        it "asks which deploy method to use" do
          cli.should_receive(:ask).with("Which deploy method to use to deploy to #{runner.environment}?", config.deploy_methods) { selected_method }
          runner.ask_method
          runner.deploy_method.should == selected_method
        end

        it "does not ask if already set" do
          runner.deploy_method = selected_method
          cli.should_not_receive(:ask)

          runner.ask_method
        end
      end

      context "#deploy" do
        let(:environment) { "foo" }
        let(:deploy_method) { "bar" }

        before do
          runner.environment = environment
          runner.deploy_method = deploy_method
          Git.stub(current_branch: "somebranch")
        end

        it "performs the deploy with the given options" do
          cli.should_receive(:perform_and_exit).with("env DEPLOY_BRANCH=#{Git.current_branch} bundle exec cap #{environment} deploy:#{deploy_method}")
          runner.deploy
        end
      end
    end
  end
end
