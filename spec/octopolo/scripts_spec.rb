require "spec_helper"
require "octopolo/scripts"

module Octopolo
  module Scripts
    describe Base do
      context ".default_option_parser(config)" do
        let(:config) { stub(:config) }

        subject { Base.default_option_parser(config) }

        context "reloading the cached API object" do
          it "reloads the cached API object if passed --reload" do
            config.should_receive(:reload_cached_api_object)

            subject.parse("--reload")
          end

          it "does not if not passed --reload" do
            config.should_receive(:reload_cached_api_object).never

            subject.parse
          end
        end

        context "overriding which application to use" do
          let(:app_name) { "foo" }

          it "sets the application name in the config if passed --app foo" do
            config.should_receive(:engine_yard_app_name=).with(app_name)

            subject.parse("--app", "foo")
          end

          it "does not if not passed --app" do
            config.should_receive(:engine_yard_app_name=).with(app_name).never

            subject.parse
          end
        end
      end
    end
  end
end
