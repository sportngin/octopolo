require "spec_helper"
require "octopolo/scripts/deployable"

module Octopolo
  module Scripts
    describe Deployable do
      let(:cli) { stub(:CLI) }
      let(:config) { stub(:Config, github_repo: "tstmedia/foo") }
      let(:pull_request_id) { 42 }
      let(:pull_request) { stub(:PullRequest, branch: "cool-feature", url: "http://example.com/") }
      let(:git) { stub(:git, deployable_branch: "deployable") }

      subject { Deployable.new '' }

      before do
        subject.git = git
        subject.config = config
        subject.cli = cli
      end

      context "#parse" do
        it "captures the pull request ID" do
          subject.parse(["#{pull_request_id}"])
          subject.pull_request_id.should == pull_request_id
        end

        it "fails if not given a pull request ID" do
          expect { subject.parse([]) }.to raise_error(Clamp::UsageError)
        end
      end

      context "#pull_request" do
        before do
          subject.pull_request_id = pull_request_id
        end

        it "finds the PullRequest for the given ID" do
          GitHub::PullRequest.should_receive(:new).with(config.github_repo, pull_request_id) { pull_request }
          subject.pull_request.should == pull_request
        end

        it "caches the PullRequest" do
          GitHub::PullRequest.should_receive(:new).once { pull_request }
          subject.pull_request
          subject.pull_request
        end
      end

      context "#execute" do
        before do
          subject.pull_request_id = pull_request_id
          subject.pull_request = pull_request
        end

        it "checks out deployable, merges the pull request's branch, and writes a comment" do
          git.stub(:if_clean).and_yield # do not yield, index is dirty
          subject.should_receive(:check_out_deployable)
          subject.should_receive(:merge_pull_request)
          subject.should_receive(:comment_about_merge)

          subject.execute
        end

        it "does nothing if the index is dirty" do
          git.stub(:if_clean) # do not yield, index is dirty
          subject.should_not_receive(:check_out_deployable)
          subject.should_not_receive(:merge_pull_request)
          subject.should_not_receive(:comment_about_merge)

          subject.execute
        end

        it "properly handles an invalid pull request ID" do
          git.should_receive(:if_clean).and_raise(GitHub::PullRequest::NotFound)
          cli.should_receive(:say).with("Unable to find pull request #{pull_request_id}. Please retry with a valid ID.")

          subject.execute
        end

        it "properly handles a failed merge" do
          git.should_receive(:if_clean).and_raise(Git::MergeFailed)
          cli.should_receive(:say).with("Merge failed. Please identify the source of this merge conflict resolve this conflict in your pull request's branch. NOTE: Merge conflicts resolved in the deployable branch are NOT used when deploying.")

          subject.execute
        end

        it "properly handles a failed checkout of deployable" do
          git.should_receive(:if_clean).and_raise(Git::CheckoutFailed)
          cli.should_receive(:say).with("Checkout of #{git.deployable_branch} failed. Please contact Infrastructure to determine the cause.")

          subject.execute
        end

        it "properly handles a failed comment" do
          git.should_receive(:if_clean).and_raise(GitHub::PullRequest::CommentFailed)
          cli.should_receive(:say).with("Unable to write comment. Please navigate to #{pull_request.url} and add the comment, '#{subject.comment_body}'")
          subject.execute
        end
      end

      context "#check_out_deployable" do
        let(:creator) { stub(:dated_branch_creator, branch_name: "new-deployable") }

        it "checks out the project's deployable branch" do
          git.should_receive(:check_out).with(git.deployable_branch)
          subject.check_out_deployable
        end

        it "creates a new deployable branch if none exists, and checks it out" do
          git.should_receive(:deployable_branch).and_raise(Git::NoBranchOfType)
          DatedBranchCreator.should_receive(:perform).with(Git::DEPLOYABLE_PREFIX) { creator }
          git.should_receive(:check_out).with(creator.branch_name)
          cli.should_receive(:say).with("No deployable branch available. Creating one now.")
          subject.check_out_deployable
        end
      end

      context "#merge_pull_request" do
        before do
          subject.pull_request = pull_request
        end

        it "merges the pull request into the checked-out deployable branch" do
          git.should_receive(:merge).with(pull_request.branch)
          subject.merge_pull_request
        end
      end

      context "#comment_about_merge" do
        before do
          subject.pull_request = pull_request
        end

        it "submits a comment that the pull request was merged into the deployable branch" do
          pull_request.should_receive(:write_comment).with(subject.comment_body)

          subject.comment_about_merge
        end
      end

      context "#comment_body" do
        it "contains the default comment body" do
          subject.comment_body.should == "Merged into #{git.deployable_branch}. /cc @tst-octopolo"
        end
      end
    end
  end
end
