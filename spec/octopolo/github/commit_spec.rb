require "spec_helper"
require_relative "../../../lib/octopolo/github"

module Octopolo
  module GitHub
    describe Commit do
      context ".new" do
        let(:commit_data) { double }

        it "remembers the commit data from GitHub API" do
          commit = Commit.new commit_data
          expect(commit.commit_data).to eq(commit_data)
        end
      end

      context "#author_name" do
        let(:commit) do
          Commit.new double
        end

        it "fetches the author name from the author" do
          allow(commit).to receive_messages(:author => double(:author_name => "pbyrne"))
          expect(commit.author_name).to eq("pbyrne")
        end
      end

      context "#author" do
        let(:commit_data) do
          double(:author => double(:login => "pbyrne"))
        end

        it "fetches the User from github" do
          commit = Commit.new commit_data
          expect(GitHub::User).to receive(:new).with("pbyrne")
          commit.author
        end

        it "gracefully handles a commit without an author" do
          commit = Commit.new author: nil
          expect(User).to receive(:new).with(GitHub::UNKNOWN_USER)
          commit.author
        end
      end

      context ".for_pull_request pull_request" do
        let(:pull_request) { double(repo_name: "foo/bar", number: 123) }
        let(:raw_commit1) { double }
        let(:raw_commits) { [raw_commit1] }
        let(:wrapper_commit) { double }

        it "fetches from octokit and returns Commit wrappers" do
          expect(GitHub).to receive(:pull_request_commits).with(pull_request.repo_name, pull_request.number) { raw_commits }
          expect(Commit).to receive(:new).with(raw_commit1) { wrapper_commit }
          expect(Commit.for_pull_request(pull_request)).to eq([wrapper_commit])
        end
      end
    end
  end
end
