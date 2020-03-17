require "spec_helper"
require "octopolo/pull_request_merger"

module Octopolo
  module Scripts
    describe PullRequestMerger do
      let(:cli) { double(:CLI) }
      let(:config) { double(:Config, github_repo: "tstmedia/foo") }
      let(:pull_request_id) { 42 }
      let(:pull_request) { double(:PullRequest, branch: "cool-feature", url: "http://example.com/") }
      let(:branch_type) { Git::DEPLOYABLE_PREFIX }
      let(:git) { double(:git, deployable_branch: "deployable") }
      let(:options) { { :user_notifications => ['NickLaMuro', 'anfleene'] } }

      subject { PullRequestMerger.new(Git::DEPLOYABLE_PREFIX, 42, options) }

      before do
        subject.git = git
        subject.config = config
        subject.cli = cli
      end

      context "#pull_request" do
        before do
          subject.pull_request_id = pull_request_id
        end

        it "finds the PullRequest for the given ID" do
          expect(GitHub::PullRequest).to receive(:new).with(config.github_repo, pull_request_id) { pull_request }
          expect(subject.pull_request).to eq(pull_request)
        end

        it "caches the PullRequest" do
          expect(GitHub::PullRequest).to receive(:new).once { pull_request }
          subject.pull_request
          subject.pull_request
        end
      end

      context "#perform" do
        before do
          subject.pull_request_id = pull_request_id
          subject.pull_request = pull_request
        end

        it "checks out branch, merges the pull request's branch, and writes a comment" do
          allow(git).to receive(:if_clean).and_yield # do not yield, index is dirty
          expect(subject).to receive(:check_out_branch)
          expect(subject).to receive(:merge_pull_request)
          expect(subject).to receive(:comment_about_merge)

          subject.perform
        end

        it "does nothing if the index is dirty" do
          allow(git).to receive(:if_clean) # do not yield, index is dirty
          expect(subject).not_to receive(:check_out_branch)
          expect(subject).not_to receive(:merge_pull_request)
          expect(subject).not_to receive(:comment_about_merge)

          subject.perform
        end

        it "properly handles an invalid pull request ID" do
          expect(git).to receive(:if_clean).and_raise(GitHub::PullRequest::NotFound)
          expect(cli).to receive(:say).with("Unable to find pull request #{pull_request_id}. Please retry with a valid ID.")

          expect { subject.perform }.to raise_error
        end

        it "properly handles a failed merge" do
          expect(git).to receive(:if_clean).and_raise(Git::MergeFailed)
          expect(cli).to receive(:say).with("Merge failed. Please identify the source of this merge conflict resolve this conflict in your pull request's branch. NOTE: Merge conflicts resolved in the deployable branch are NOT used when deploying.")

          expect { subject.perform }.to raise_error
        end

        it "properly handles a failed checkout of branch" do
          expect(git).to receive(:if_clean).and_raise(Git::CheckoutFailed)
          expect(git).to receive(:latest_branch_for).with("deployable").and_return("deployable")
          expect(cli).to receive(:say).with("Checkout of #{git.deployable_branch} failed. Please contact Infrastructure to determine the cause.")

          expect { subject.perform }.to raise_error
        end

        it "properly handles a failed comment" do
          expect(git).to receive(:if_clean).and_raise(GitHub::PullRequest::CommentFailed)
          expect(git).to receive(:latest_branch_for).with("deployable").and_return("deployable")
          expect(cli).to receive(:say).with("Unable to write comment. Please navigate to #{pull_request.url} and add the comment, '#{subject.comment_body}'")

          expect { subject.perform }.to raise_error
        end
      end

      context "#check_out_branch" do
        let(:creator) { double(:dated_branch_creator, branch_name: "new-deployable") }

        it "checks out the project's deployable branch" do
          expect(git).to receive(:check_out).with(git.deployable_branch)
          expect(git).to receive(:latest_branch_for).with("deployable").and_return("deployable")
          subject.check_out_branch
        end

        it "creates a new deployable branch if none exists, and checks it out" do
          expect(git).to receive(:latest_branch_for).with(Git::DEPLOYABLE_PREFIX).and_raise(Git::NoBranchOfType)
          expect(DatedBranchCreator).to receive(:perform).with(Git::DEPLOYABLE_PREFIX) { creator }
          expect(git).to receive(:check_out).with(creator.branch_name)
          expect(cli).to receive(:say).with("No deployable branch available. Creating one now.")
          subject.check_out_branch
        end
      end

      context "#merge_pull_request" do
        before do
          subject.pull_request = pull_request
        end

        it "merges the pull request into the checked-out branch" do
          expect(git).to receive(:merge).with(pull_request.branch)
          subject.merge_pull_request
        end
      end

      context "#comment_about_merge" do
        before do
          subject.pull_request = pull_request
        end

        it "submits a comment that the pull request was merged into the branch" do
          expect(git).to receive(:latest_branch_for).with("deployable").and_return("deployable")
          expect(pull_request).to receive(:write_comment).with(subject.comment_body)

          subject.comment_about_merge
        end
      end

      context "#comment_body" do
        it "contains the default comment body" do
          expect(git).to receive(:latest_branch_for).with("deployable").and_return("deployable")
          expect(subject.comment_body).to eq("Merged into #{git.deployable_branch}. /cc @NickLaMuro @anfleene")
        end
      end
    end
  end
end
