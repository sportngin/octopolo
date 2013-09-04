require "spec_helper"
require "automation/scripts/github_auth"

module Automation
  module Scripts
    describe GithubAuth do
      let(:user_config) { stub(:user_config) }
      let(:cli) { stub(:cli) }
      let(:username) { "username" }
      let(:password) { "password" }


      subject { GithubAuth.new '' }

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
          subject.should_receive(:request_token).and_raise(GitHub::BadCredentials.new(bad_credentials_message))
          subject.should_not_receive(:store_token)
          cli.should_receive(:say).with(bad_credentials_message)

          expect { subject.execute }.to_not raise_error
        end
      end

      context "#ask_credentials" do
        it "asks for and captures the user's GitHub credentials" do
          cli.should_receive(:prompt).with("Your GitHub username: ") { username }
          cli.should_receive(:prompt_secret).with("Your GitHub password (never stored): ") { password }
          subject.send(:ask_credentials)
          expect(subject.username).to eq(username)
          expect(subject.password).to eq(password)
        end
      end

      context "#request_token" do
        let(:json_response) { '{"foo": "bar"}' }
        let(:parsed_response) { JSON.parse(json_response) }

        before do
          subject.username = username
          subject.password = password
        end

        it "requests an auth token from GitHub's API and captures the HTTP response" do
          cli.should_receive(:perform_quietly).with(%Q(curl -u '#{username}:#{password}' -d '{"scopes": ["repo"], "notes": "TST Automation"}' https://api.github.com/authorizations)) { json_response }
          subject.send(:request_token)
          expect(subject.auth_response).to eq(parsed_response)
        end
      end

      context "#store_token" do
        let(:token) { "asdf" }
        let(:good_response) { {"token" => token} }
        let(:bad_response) { {"error" => "we hate you!"} }

        before do
          subject.username = username
        end

        it "stores the username and token if receiving a token from GitHub" do
          subject.auth_response = good_response
          user_config.should_receive(:set).with(:github_user, username)
          user_config.should_receive(:set).with(:github_token, token)
          cli.should_receive(:say).with("Successfully generated GitHub API token.")
          subject.send(:store_token)
        end

        it "raises an exception if not receiving a token from GitHub" do
          subject.auth_response = bad_response
          expect { subject.send(:store_token) }.to raise_error(GitHub::BadCredentials)
        end
      end
    end
  end
end

