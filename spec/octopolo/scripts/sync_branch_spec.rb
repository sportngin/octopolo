require "spec_helper"
require_relative "../../../lib/octopolo/scripts/sync_branch"

module Octopolo
  module Scripts
    describe SyncBranch do
      let(:config) { stub(:config, :deploy_branch => "production") }
      let(:git) { stub(:Git) }
      let(:cli) { stub(:CLI) }
      let(:otherbranch) { "otherbranch" }

      subject { SyncBranch.new '' }

      before do
        subject.config = config
        subject.git = git
        subject.cli = cli
      end

      context "#parse" do
        it "accepts the given branch name as the branch to merge" do
          subject.parse([otherbranch])
          expect(subject.branch).to eq(otherbranch)
        end

        it "defaults to the deploy branch" do
          subject.parse([])
          expect(subject.branch).to eq(config.deploy_branch)
        end
      end

      context "#execute" do
        it "merges the remote branch into yours" do
          subject.should_receive(:merge_branch)
          subject.execute
        end
      end

      context "#merge_branch" do
        before do
          subject.branch = otherbranch
        end

        it "merges the remote branch into yours" do
          git.should_receive(:merge).with(subject.branch)
          subject.merge_branch
        end

        it "properly handles a merge failure" do
          git.should_receive(:merge).and_raise(Git::MergeFailed)
          cli.should_receive(:say).with("Merge failed. Please resolve these conflicts.")
          subject.merge_branch
        end
      end
    end
  end
end
