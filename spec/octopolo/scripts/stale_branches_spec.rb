require "spec_helper"
require "octopolo/scripts/stale_branches"

module Octopolo
  module Scripts
    describe StaleBranches do
      # stub any attributes in the config that you need
      let(:config) { stub(:config, :deploy_branch => "production", :branches_to_keep => %w(master production staging)) }
      let(:cli) { stub(:cli) }
      let(:git) { stub(:Git)}

      subject { StaleBranches.new '' }

      before do
        subject.cli = cli
        subject.config = config
        subject.git = git
      end

      context "#parse" do
        it "accepts a --delete flag to trigger deletes" do
          subject.parse(["--delete"])
          expect(subject.delete?).to be_true
        end

        it "defaults to not delete" do
          subject.parse([])
          expect(subject.delete?).to be_false
        end
      end

      context "#execute" do
        it "displays the stale branches if not deleting" do
          subject.delete = false
          subject.should_receive(:display_stale_branches)
          subject.should_not_receive(:delete_stale_branches)
          subject.execute
        end

        it "deletes the branches if deleting" do
          subject.delete = true
          subject.should_not_receive(:display_stale_branches)
          subject.should_receive(:delete_stale_branches)
          subject.execute
        end
      end

      context "#display_stale_branches" do
        before do
          subject.stub(:stale_branches) { %w(foo bar) }
        end

        it "displays a list of stale branches" do
          cli.should_receive(:say).with("* foo")
          cli.should_receive(:say).with("* bar")
          subject.send(:display_stale_branches)
        end
      end

      context "#delete_stale_branches" do
        before do
          subject.stub(:stale_branches) { %w(foo bar) }
        end

        it "deletes each stale branch" do
          git.should_receive(:delete_branch).with("foo")
          git.should_receive(:delete_branch).with("bar")
          subject.send(:delete_stale_branches)
        end
      end

      context "#stale_branches" do
        it "fetches from the git wrapper" do
          git.should_receive(:stale_branches).with(config.deploy_branch, config.branches_to_keep)
          subject.send(:stale_branches)
        end
      end
    end
  end
end

