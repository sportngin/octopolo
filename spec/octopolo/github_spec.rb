require "spec_helper"
require_relative "../../lib/octopolo/github"

module Octopolo
  describe GitHub do
    context ".client" do
      let(:octokit_client) { double(:github_client) }
      let(:user_config) { double(:user_config, github_user: "foo", github_token: "bar") }

      before do
        GitHub.stub(user_config: user_config)
      end

      it "logs in with the configured authentication values" do
        Octokit::Client.should_receive(:new).with(login: user_config.github_user, access_token: user_config.github_token) { octokit_client }
        GitHub.client.should eq(octokit_client)
      end

      it "uses additional given parameters" do
        Octokit::Client.should_receive(:new).with(login: user_config.github_user, access_token: user_config.github_token, auto_traversal: true) { octokit_client }
        GitHub.client(auto_traversal: true).should eq(octokit_client)
      end

      it "properly handles if the github authentication isn't configured" do
        user_config.should_receive(:github_user).and_raise(UserConfig::MissingGitHubAuth)
        Scripts::GithubAuth.should_not_receive(:execute)
        expect { GitHub.client }.to raise_error(GitHub::TryAgain, "No GitHub API token stored. Please run `op github-auth` to generate your token.")
      end
    end

    context ".crawling_client" do
      let(:client) { double }

      it "instantiates a client with auto_traversal" do
        GitHub.should_receive(:client).with(auto_traversal: true) { client }
        GitHub.crawling_client.should eq(client)
      end
    end

    context "having convenience methods" do
      let(:client) { double(:github_client) }
      let(:crawling_client) { double(:github_crawling_client) }
      let(:data) { double }

      before do
        GitHub.stub(client: client, crawling_client: crawling_client)
      end

      context ".pull_request *args" do
        it "sends onto the client wrapper" do
          client.should_receive(:pull_request).with("a", "b") { data }
          result = GitHub.pull_request("a", "b")
          result.should eq(data)
        end
      end

      context ".issue *args" do
        it "sends onto the client wrapper" do
          client.should_receive(:issue).with("a", "b") { data }
          result = GitHub.issue("a", "b")
          result.should eq(data)
        end
      end

      context ".pull_request_commits *args" do
        it "sends onto the client wrapper" do
          client.should_receive(:pull_request_commits).with("a", "b") { data }
          result = GitHub.pull_request_commits("a", "b")
          result.should eq(data)
        end
      end

      context ".issue_comments *args" do
        it "sends onto the client wrapper" do
          client.should_receive(:issue_comments).with("a", "b") { data }
          result = GitHub.issue_comments("a", "b")
          result.should eq(data)
        end
      end

      context ".pull_requests *args" do
        it "sends onto the crawling client wrapper" do
          crawling_client.should_receive(:pull_requests).with("a", "b") { data }
          GitHub.pull_requests("a", "b").should eq(data)
        end
      end

      context ".tst_repos" do
        it "fetches the sportngin organization repos" do
          crawling_client.should_receive(:organization_repositories).with("sportngin") { data }
          GitHub.org_repos.should eq(data)
        end

        it "fetches another organization's repos if requested" do
          crawling_client.should_receive(:organization_repositories).with("foo") { data }
          GitHub.org_repos("foo").should eq(data)
        end
      end

      context ".create_pull_request" do
        it "sends the pull request to the API" do
          client.should_receive(:create_pull_request).with("repo", "destination_branch", "source_branch", "title", "body") { data }
          GitHub.create_pull_request("repo", "destination_branch", "source_branch", "title", "body").should eq(data)
        end
      end

      context ".create_issue" do
        it "sends the issue to the API" do
          client.should_receive(:create_issue).with("repo", "title", "body") { data }
          GitHub.create_issue("repo", "title", "body").should eq(data)
        end
      end

      context ".add_comment" do
        it "sends the comment to the API" do
          client.should_receive(:add_comment).with("repo", 123, "contents of comment")
          GitHub.add_comment "repo", 123, "contents of comment"
        end
      end

      context ".user username" do
        let(:username) { "foo" }
        let(:valid_user) { double(login: "foo", name: "Joe Foo")}

        it "fetches the user data from GitHub" do
          client.should_receive(:user).with(username) { valid_user }
          GitHub.user(username).should eq(valid_user)
        end

        it "returns a generic Unknown user if none is found" do
          client.should_receive(:user).with(username).and_raise(Octokit::NotFound)
          GitHub.user(username).should eq(Hashie::Mash.new(name: GitHub::UNKNOWN_USER))
        end
      end

      context ".check_connection" do
        it "performs a request against the API which requires authentication" do
          client.should_receive(:user)
          GitHub.check_connection
        end

        it "raises BadCredentials if testing the connection raises Octokit::Unauthorized" do
          client.should_receive(:user).and_raise(Octokit::Unauthorized)
          expect { GitHub.check_connection }.to raise_error(GitHub::BadCredentials)
        end
      end

      context ".connect &block" do
        let(:thing) { double }
        let(:try_again) { GitHub::TryAgain.new("try-again message") }
        let(:bad_credentials) { GitHub::BadCredentials.new("bad-credentials message") }

        it "performs the block if GitHub.check_connection does not raise an exception" do
          GitHub.should_receive(:check_connection)
          thing.should_receive(:foo)

          GitHub.connect do
            thing.foo
          end
        end

        it "does not perform the block if GitHub.check_connection raises TryAgain" do
          GitHub.should_receive(:check_connection).and_raise(try_again)
          thing.should_not_receive(:foo)
          CLI.should_receive(:say).with(try_again.message)

          GitHub.connect do
            thing.foo
          end
        end

        it "does not perform the block if GitHub.check_connection raises BadCredentials" do
          GitHub.should_receive(:check_connection).and_raise(bad_credentials)
          thing.should_not_receive(:foo)
          CLI.should_receive(:say).with(bad_credentials.message)

          GitHub.connect do
            thing.foo
          end
        end
      end

      context ".team_member? team" do
        let(:valid_team) { 2396228 }
        let(:invalid_team) { 2396227 }
        let(:user_config) { double(:user_config, github_user: "foo", github_token: "bar") }

        before { GitHub.stub(user_config: user_config) }

        context "when valid team member" do
          it "returns true" do
            client.should_receive(:team_member?).with(valid_team, user_config.github_user) { true }
            GitHub.team_member?(valid_team).should eq(true)
          end
        end

        context "when not a valid team member" do
          it "returns false" do
            client.should_receive(:team_member?).with(invalid_team, user_config.github_user) { false }
            GitHub.team_member?(invalid_team).should eq(false)
          end
        end
      end
    end
  end
end
