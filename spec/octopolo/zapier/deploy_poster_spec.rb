#<Encoding:UTF-8>
require "spec_helper"
require "octopolo/zapier/deploy_poster"

module Octopolo
  module Zapier
    describe DeployPoster do
      let(:poster) { DeployPoster.new app_name, env_name, deploy_type }
      let(:app_name) { "app_name" }
      let(:env_name) { "env_name" }
      let(:deploy_type) { "deploy_type" }
      let(:user_config) { stub(:user_config, full_name: "Spec User") }
      let(:cli) { stub(:CLI) }

      context ".new" do
        it "retains the options provided to it" do
          poster = DeployPoster.new app_name, env_name, deploy_type
          poster.app_name.should == app_name
          poster.env_name.should == env_name
          poster.deploy_type.should == deploy_type
        end
      end

      context "#perform phase" do
        let(:message) { stub }
        let(:phase) { stub }

        it "posts the appropriate message for the given deploy phase" do
          poster.should_receive(:message_for).with(phase) { message }
          poster.should_receive(:post).with(message)
          poster.perform phase
        end
      end

      context "#post message" do
        let(:message) { "the message" }
        let(:apostrophe) { "joe user's message" }
        let(:command) { %Q(curl -H 'Content-Type: application/json' -X POST -d '{"message": "#{message}"}' '#{Zapier.endpoint(Zapier::MESSAGE_TO_DEVO)}') }
        let(:apostrophe_command) { %Q(curl -H 'Content-Type: application/json' -X POST -d '{"message": "joe users message"}' '#{Zapier.endpoint(Zapier::MESSAGE_TO_DEVO)}') }

        before do
          poster.cli = cli
        end

        it "encodes the message as JSON and posts to correct URL" do
          cli.should_receive(:perform_quietly).with(command)
          poster.post message
        end

        it "deletes apostrophes in the message because bash" do
          cli.should_receive(:perform_quietly).with(apostrophe_command)
          poster.post apostrophe
        end
      end

      context "#message_for phase" do
        before do
          poster.user_config = user_config
        end

        it "knows about starting a deploy" do
          poster.should_receive(:environment_emoji) { ":environment:" }
          poster.should_receive(:type_emoji) { ":type:" }
          poster.message_for(DeployPoster::START).should == ":environment::type: #{user_config.full_name} is STARTING a #{deploy_type} deploy to #{app_name} #{env_name}."
        end

        it "knows about finishing a deploy" do
          poster.should_receive(:environment_emoji) { ":environment:" }
          poster.should_receive(:finished_emoji) { ":finished:" }
          poster.message_for(DeployPoster::FINISH).should == ":environment::finished: #{user_config.full_name} is DONE deploying to #{app_name} #{env_name}."
        end

        it "knows about when a deploy fails" do
          poster.message_for(DeployPoster::ERROR).should == "#{poster.failed_emoji} Something went wrong with #{user_config.full_name}’s deploy to #{app_name} #{env_name}. Please correct the problem and redeploy."
        end
      end

      context "#type_emoji" do
        it "should use :zap: for fast deploys" do
          poster.stub(deploy_type: "fast")
          poster.type_emoji.should == ":zap:"
        end

        it "should use :turtle: for rolling deploys" do
          poster.stub(deploy_type: "rolling")
          poster.type_emoji.should == ":turtle:"
        end

        it "should use :turtle: for migration deploys" do
          poster.stub(deploy_type: "rolling_migrations")
          poster.type_emoji.should == ":turtle:"
        end

        it "should use :zap: for hot deploys" do
          poster.stub(deploy_type: "hot")
          poster.type_emoji.should == ":zap:"
        end

        it "should use :zap: for soft deploys" do
          poster.stub(deploy_type: "soft")
          poster.type_emoji.should == ":zap:"
        end

        it "should use :zap: for hard deploys" do
          poster.stub(deploy_type: "hard")
          poster.type_emoji.should == ":zap:"
        end

        it "should use :grey_question: for an unknown deploy type" do
          poster.stub(deploy_type: "asdfasdfasdf")
          poster.type_emoji.should == ":grey_question:"
        end
      end

      context "#finished_emoji" do
        it "should be :punch:" do
          poster.finished_emoji.should == ":punch:"
        end
      end

      context "#failed_emoji" do
        it "should be :poop:" do
          poster.failed_emoji.should == ":poop:"
        end
      end

      context "#environment_emoji" do
        it "should be :shipit: for production deploys" do
          poster.env_name = "foo_production"
          poster.environment_emoji.should == ":shipit:"
        end

        it "should be empty for other deploys" do
          poster.env_name = "foo_staging"
          poster.environment_emoji.should == ""
        end
      end
    end
  end
end
