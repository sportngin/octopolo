require "spec_helper"
require "octopolo/scripts/sync_branch"

module Octopolo
  module Scripts
    describe SyncBranch do
      let(:config) { double(:config, :deploy_branch => "production") }
      let(:git) { double(:Git) }
      let(:cli) { double(:CLI) }
      let(:otherbranch) { "otherbranch" }

      subject { SyncBranch.new }

      before do
        allow_any_instance_of(SyncBranch).to receive_messages({
          :config => config,
          :git => git,
          :cli => cli
        })
      end

      context "#parse" do
        it "accepts the given branch name as the branch to merge" do
          expect(SyncBranch.new(otherbranch).branch).to eq(otherbranch)
        end

        it "defaults to the deploy branch" do
          expect(subject.branch).to eq(config.deploy_branch)
        end
      end

      context "#execute" do
        it "merges the remote branch into yours" do
          expect(subject).to receive(:merge_branch)
          subject.execute
        end
      end

      context "#merge_branch" do
        before do
          subject.branch = otherbranch
        end

        it "merges the remote branch into yours" do
          expect(git).to receive(:merge).with(subject.branch)
          subject.merge_branch
        end

        it "properly handles a merge failure" do
          expect(git).to receive(:merge).and_raise(Git::MergeFailed)
          expect(cli).to receive(:say).with("Merge failed. Please resolve these conflicts.")
          subject.merge_branch
        end
      end
    end
  end
end
