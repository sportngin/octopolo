require "spec_helper"
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
        allow_any_instance_of(StaleBranches).to receive_messages({
          :cli => cli,
          :config => config,
          :git => git
        })
      end

      context "#new" do
        it "accepts a delete attribute to trigger deletes" do
          expect(StaleBranches.new(true).delete?).to be_truthy
        end

        it "defaults to not delete" do
          expect(subject.delete?).to be_falsey
        end
      end

      context "#execute" do
        it "displays the stale branches if not deleting" do
          subject.delete = false
          expect(subject).to receive(:display_stale_branches)
          expect(subject).not_to receive(:delete_stale_branches)
          subject.execute
        end

        it "deletes the branches if deleting" do
          subject.delete = true
          expect(subject).not_to receive(:display_stale_branches)
          expect(subject).to receive(:delete_stale_branches)
          subject.execute
        end
      end

      context "#display_stale_branches" do
        before do
          allow(subject).to receive(:stale_branches) { %w(foo bar) }
        end

        it "displays a list of stale branches" do
          expect(cli).to receive(:say).with("* foo")
          expect(cli).to receive(:say).with("* bar")
          subject.send(:display_stale_branches)
        end
      end

      context "#delete_stale_branches" do
        before do
          allow(subject).to receive(:stale_branches) { %w(foo bar) }
        end

        it "deletes each stale branch" do
          expect(git).to receive(:delete_branch).with("foo")
          expect(git).to receive(:delete_branch).with("bar")
          subject.send(:delete_stale_branches)
        end
      end

      context "#stale_branches" do
        it "fetches from the git wrapper" do
          expect(git).to receive(:stale_branches).with(config.deploy_branch, config.branches_to_keep)
          subject.send(:stale_branches)
        end
      end
    end
  end
end

