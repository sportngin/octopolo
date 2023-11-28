require_relative "../../../lib/octopolo/github"

module Octopolo
  module GitHub
    describe Commit do
      context ".new" do
        let(:commit_data) { double }

        it "remembers the commit data from GitHub API" do
          commit = Commit.new commit_data
          commit.commit_data.should eq(commit_data)
        end
      end

      context "#author_name" do
        let(:commit) do
          Commit.new double()
        end

        it "fetches the author name from the author" do
          commit.stub(:author => double(:author_name => "pbyrne"))
          commit.author_name.should eq("pbyrne")
        end
      end

      context "#author" do
        let(:commit_data) do
          double(:author => double(:login => "pbyrne"))
        end

        it "fetches the User from github" do
          commit = Commit.new commit_data
          GitHub::User.should_receive(:new).with("pbyrne")
          commit.author
        end

        it "gracefully handles a commit without an author" do
          commit = Commit.new author: nil
          User.should_receive(:new).with(GitHub::UNKNOWN_USER)
          commit.author
        end
      end

      context ".for_pull_request pull_request" do
        let(:pull_request) { double(repo_name: "foo/bar", number: 123) }
        let(:raw_commit1) { double }
        let(:raw_commits) { [raw_commit1] }
        let(:wrapper_commit) { double }

        it "fetches from octokit and returns Commit wrappers" do
          GitHub.should_receive(:pull_request_commits).with(pull_request.repo_name, pull_request.number) { raw_commits }
          Commit.should_receive(:new).with(raw_commit1) { wrapper_commit }
          Commit.for_pull_request(pull_request).should eq([wrapper_commit])
        end
      end
    end
  end
end
