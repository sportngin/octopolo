require "spec_helper"
require_relative "../../../lib/octopolo/scripts/qaready"

module Octopolo
  module Scripts
    describe Qaready do
      # stub any attributes in the config that you need
      let(:config) { stub(:config, github_repo: "sportngin/foo", deploy_branch: "master") }
      let(:cli) { stub(:cli) }
      let(:git) { stub(:git, qaready_branch: "qaready1") }
      let(:pull_request_id) { 123 }
      let(:pull_request) { stub(:pull_request, branch: "pull-request-branch") }

      subject { Qaready.new '' }

      before do
        subject.cli = cli
        subject.config = config
        subject.git = git
      end

      context "#parse" do
        it "captures the pull request ID" do
          subject.parse([pull_request_id.to_s])
          subject.pull_request_id.should == pull_request_id
        end

        it "fails if not given a pull request ID" do
          expect { subject.parse([]) }.to raise_error(Clamp::UsageError)
        end
      end

      context "#execute" do
        it "merges master and the pull request, then puts a comment in" do
          GitHub.should_receive(:connect).and_yield

          subject.should_receive(:check_out_qaready)
          subject.should_receive(:merge_master)
          subject.should_receive(:merge_pull_request)
          subject.should_receive(:write_comment)

          subject.execute
        end

        it "does nothing if can't connect to GitHub" do
          GitHub.should_receive(:connect) # and not yield

          subject.should_not_receive(:merge_master)
          subject.should_not_receive(:merge_pull_request)
          subject.should_not_receive(:write_comment)

          subject.execute
        end
      end

      context "#pull_request" do
        before do
          subject.pull_request_id = pull_request_id
        end

        it "finds the PullRequest for the given ID" do
          GitHub::PullRequest.should_receive(:new).with(config.github_repo, pull_request_id) { pull_request }
          expect(subject.send :pull_request).to eq pull_request
        end

        it "caches the PullRequest" do
          GitHub::PullRequest.should_receive(:new).once { pull_request }
          subject.send :pull_request
          subject.send :pull_request
        end
      end

      context "#check_out_qaready" do
        it "checks out the current QA-ready branch" do
          git.should_receive(:check_out).with(git.qaready_branch)
          subject.send(:check_out_qaready)
        end
      end

      context "#merge_master" do
        it "merges the master branch" do
          git.should_receive(:merge).with(config.deploy_branch)
          subject.send(:merge_master)
        end
      end

      context "#merge_pull_request" do
        before do
          subject.pull_request = pull_request
        end

        it "merges the pull request's branch" do
          git.should_receive(:merge).with(pull_request.branch)
          subject.send(:merge_pull_request)
        end
      end

      context "#write_comment" do
        before do
          subject.pull_request = pull_request
        end

        it "comments that the branch was merged into QA-ready" do
          pull_request.should_receive(:write_comment).with("Merged into #{git.qaready_branch}.")
          subject.send(:write_comment)
        end
      end

    end
  end
end

# vim: set ft=ruby : #
