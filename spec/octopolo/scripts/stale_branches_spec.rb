require "octopolo/scripts/stale_branches"

module Octopolo
  module Scripts
    describe StaleBranches do
      # stub any attributes in the config that you need
      let(:config) { double(:config, :deploy_branch => "production", :branches_to_keep => %w(master production staging)) }
      let(:cli) { double(:cli) }
      let(:git) { double(:Git)}

      subject { StaleBranches.new }

      before do
        StaleBranches.any_instance.stub({
          :cli => cli,
          :config => config,
          :git => git
        })
      end

      context "#new" do
        it "accepts a delete attribute to trigger deletes" do
          expect(StaleBranches.new(true).delete?).to be true
        end

        it "defaults to not delete" do
          expect(subject.delete?).to be false
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

