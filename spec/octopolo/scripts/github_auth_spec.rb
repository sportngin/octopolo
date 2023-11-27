require "octopolo/scripts/github_auth"

module Octopolo
  module Scripts
    describe GithubAuth do
      let(:user_config) { double(:user_config) }
      let(:cli) { double(:cli) }
      let(:username) { "username" }
      let(:password) { "password" }
      let(:user_defined_token) { "123456789" }


      subject { GithubAuth.new }

      before do
        subject.cli = cli
        subject.user_config = user_config
      end

      context "#execute" do
        let(:bad_credentials_message) { "OMG TYPE IT RIGHT" }

        it "asks for username and password when that option is selected, generates the token, and writes to disk" do
          subject.should_receive(:ask_auth_method).and_return("Generate an API token with my credentials")
          subject.should_receive(:ask_credentials)
          subject.should_receive(:request_token)
          subject.should_receive(:store_token)

          subject.should_not_receive(:ask_token)

          subject.execute
        end

        it "gracefully handles invalid credentials" do
          subject.should_receive(:ask_auth_method).and_return("Generate an API token with my credentials")
          subject.should_receive(:ask_credentials)
          subject.should_receive(:request_token).and_raise(GitHub::BadCredentials.new(bad_credentials_message))
          subject.should_not_receive(:store_token)
          cli.should_receive(:say).with(bad_credentials_message)

          expect { subject.execute }.to_not raise_error
        end

        it "asks for a token when that option is selected, and writes to disk" do
          subject.should_receive(:ask_auth_method).and_return("I'll enter an access token manually")
          subject.should_receive(:ask_token)
          subject.should_receive(:verify_token)
          subject.should_receive(:store_token)

          subject.should_not_receive(:ask_credentials)
          subject.should_not_receive(:request_token)

          subject.execute
        end

        it "gracefully handles an invalid token" do
          subject.should_receive(:ask_auth_method).and_return("I'll enter an access token manually")
          subject.should_receive(:ask_token)
          subject.should_receive(:verify_token).and_raise(GitHub::BadCredentials.new(bad_credentials_message))
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

      context "#ask_token" do
        it "asks for and captures the user's manually entered access token" do
          cli.should_receive(:prompt).with("Your GitHub username: ") { username }
          cli.should_receive(:prompt_secret).with("Your GitHub API token: ") { user_defined_token }
          subject.send(:ask_token)
          expect(subject.username).to eq(username)
          expect(subject.user_defined_token).to eq(user_defined_token)
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
          cli.should_receive(:perform_quietly).with(%Q(curl -u '#{username}:#{password}' -d '{"scopes": ["repo"], "notes": "Octopolo"}' https://api.github.com/authorizations)) { json_response }
          subject.send(:request_token)
          expect(subject.auth_response).to eq(parsed_response)
        end
      end

      context "#verify_token" do
        let(:json_response) { '{"foo": "bar"}' }
        let(:parsed_response) { JSON.parse(json_response) }

        before do
          subject.username = username
          subject.user_defined_token = user_defined_token
        end

        it "verifies that a user_defined_token properly authenticates with the GitHub API" do
          cli.should_receive(:perform_quietly).with(%Q(curl -u #{user_defined_token}:x-oauth-basic https://api.github.com/user)) { json_response }
          subject.send(:verify_token)
          expect(subject.auth_response).to eq(parsed_response)
        end
      end

      context "#store_token" do
        let(:token) { "asdf" }
        let(:url) { "www.example.com" }
        let(:good_response_request) { {"token" => token} }
        let(:good_response_verify) { {"login" => username} }
        let(:bad_response) { {"error" => "we hate you!", "message" => "Bad Credentials"} }

        before do
          subject.username = username
        end

        it "stores the username and token if receiving a token from GitHub" do
          subject.auth_response = good_response_request
          user_config.should_receive(:set).with(:github_user, username)
          user_config.should_receive(:set).with(:github_token, token)
          cli.should_receive(:say).with("Successfully stored GitHub API token.")
          subject.send(:store_token)
        end

        it "raises an exception if token was not received from GitHub and one wasn't manually entered" do
          subject.auth_response = bad_response
          expect { subject.send(:store_token) }.to raise_error(GitHub::BadCredentials)
        end

        it "stores the token if a token has been manually entered" do
          subject.auth_response = good_response_verify
          subject.user_defined_token = user_defined_token
          user_config.should_receive(:set).with(:github_user, username)
          user_config.should_receive(:set).with(:github_token, user_defined_token)
          cli.should_receive(:say).with("Successfully stored GitHub API token.")
          subject.send(:store_token)
        end
      end
    end
  end
end

