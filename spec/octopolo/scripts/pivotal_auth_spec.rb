require "spec_helper"
require "automation/scripts/pivotal_auth"

module Automation
  module Scripts
    describe PivotalAuth do
      # stub any attributes in the config that you need
      let(:user_config) { stub(:user_config) }
      let(:cli) { stub(:cli) }
      let(:email) { "example@example.com" }
      let(:password) { "don't tell anyone" }
      let(:client) { stub(:pivotal_client) }
      let(:token) { "deadbeef" }

      subject { PivotalAuth.new '' }

      before do
        subject.cli = cli
        subject.user_config = user_config
      end

      context "#execute" do
        let(:bad_credentials_message) { "OMG TYPE IT RIGHT" }

        it "asks for username and password, generates the token, and writes to disk" do
          subject.should_receive(:ask_credentials)
          subject.should_receive(:request_token)
          subject.should_receive(:store_token)

          subject.execute
        end

        it "gracefully handles invalid credentials" do
          subject.should_receive(:ask_credentials)
          subject.should_receive(:request_token).and_raise(Pivotal::BadCredentials.new(bad_credentials_message))
          subject.should_not_receive(:store_token)
          cli.should_receive(:say).with(bad_credentials_message)

          expect { subject.execute }.to_not raise_error
        end
      end

      context "#ask_credentials" do
        it "asks for and captures the user's Pivotal Tracker credentials" do
          cli.should_receive(:prompt).with("Your Pivotal Tracker email: ") { email }
          cli.should_receive(:prompt_secret).with("Your Pivotal Tracker password (never stored): ") { password }
          subject.send(:ask_credentials)
          expect(subject.email).to eq(email)
          expect(subject.password).to eq(password)
        end
      end

      context "#request_token" do
        before do
          subject.email = email
          subject.password = password
        end

        it "leverages the Pivotal Tracker client to fetch the token via API" do
          Pivotal::Client.should_receive(:fetch_token).with(email, password) { token }
          subject.send(:request_token)
          expect(subject.token).to eq(token)
        end
      end

      context "#store_token" do
        it "stores the token in the config" do
          subject.token = token
          user_config.should_receive(:set).with(:pivotal_token, token)
          subject.send(:store_token)
        end
      end
    end
  end
end

# vim: set ft=ruby : #
