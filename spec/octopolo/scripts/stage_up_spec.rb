require "spec_helper"
require "automation/scripts/stage_up"

module Automation
  module Scripts
    describe StageUp do
      let(:git) { stub(:git, current_branch: "current_branch") }
      let(:cli) { stub(:cli) }
      let(:branchname) { "fakebranchname" }
      let(:staging) { "staging.12.34" }

      subject { StageUp.new '' }

      before do
        subject.git = git
        subject.cli = cli
      end

      context "#parse" do
        it "captures the given branchname" do
          subject.parse([branchname])
          expect(subject.branch).to eq(branchname)
        end

        it "defaults to nil" do
          subject.parse([])
          expect(subject.branch).to be_nil
        end
      end

      context "#execute" do
        it "checks out the staging branch and merges the given branch into it" do
          git.stub(:if_clean).and_yield
          subject.should_receive(:check_out_staging)
          subject.should_receive(:merge_given_branch)
          subject.execute
        end

        it "does nothing if the git index isn't clean" do
          git.stub(:if_clean) # do not yield, because not clean
          subject.should_not_receive(:check_out_staging)
          subject.should_not_receive(:merge_given_branch)
          subject.execute
        end
      end

      context "#check_out_staging" do
        let(:creator) { stub(:dated_branch_creator, branch_name: "asdf") }

        before do
          git.stub(staging_branch: staging)
        end

        it "checks out the project's staging branch" do
          git.should_receive(:check_out).with(staging)
          subject.check_out_staging
        end

        it "creates a new staging branch if none exists and checks it out" do
          git.should_receive(:staging_branch).and_raise(Git::NoBranchOfType)
          cli.should_receive(:say).with("No staging branch available. Creating one now.")
          DatedBranchCreator.should_receive(:perform).with(Git::STAGING_PREFIX) { creator }
          git.should_receive(:check_out).with(creator.branch_name)
          subject.check_out_staging
        end

        it "captures the current branch before checking out if not set" do
          subject.branch = nil
          git.stub(:check_out) # don't care about this
          subject.check_out_staging
          expect(subject.branch).to eq(git.current_branch)
        end
      end

      context "#merge_given_branch" do
        before do
          subject.branch = branchname
        end

        it "merges the given branch into the checked-out staging branch" do
          git.should_receive(:merge).with(branchname)
          subject.merge_given_branch
        end

        it "gracefully handles a merge conflict" do
          git.stub(:staging_branch) { staging }
          git.should_receive(:merge).and_raise(Git::MergeFailed)
          cli.should_receive(:say).with("Merge of #{branchname} into #{git.staging_branch} has failed. Please resolve these conflicts.")
          subject.merge_given_branch
        end
      end
    end
  end
end

