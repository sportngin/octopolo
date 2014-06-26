require "spec_helper"
require "octopolo/scripts/deployable"

module Octopolo
  module Scripts
    describe Deployable do
      let(:cli) { stub(:Cli) }
      let(:config) { stub(:user_notifications => ['NickLaMuro']) }
      before { Deployable.any_instance.stub(:cli => cli, :config => config) }

      context "#execute" do
        context "with a PR passed in via the command args" do
          subject { Deployable.new 42 }

          it "delegates the work to PullRequestMerger" do
            PullRequestMerger.should_receive(:perform).with(Git::DEPLOYABLE_PREFIX, 42, :user_notifications => ["NickLaMuro"])
            subject.execute
          end
        end

        context "with no PR passed in from the command args" do
          subject { Deployable.new }

          context "with a PR passed in through the cli" do
            before do
              cli.should_receive(:prompt)
                 .with("Pull Request ID: ")
                 .and_return("42")
            end

            it "delegates the work to PullRequestMerger" do
              PullRequestMerger.should_receive(:perform).with(Git::DEPLOYABLE_PREFIX, 42, :user_notifications => ["NickLaMuro"])
              subject.execute
            end
          end

          context "with no PR passed in from the cli" do
            before do
              cli.should_receive(:prompt)
                 .with("Pull Request ID: ")
                 .and_return("foo")
            end

            it "delegates the work to PullRequestMerger" do
              expect{ subject.execute }.to raise_error(ArgumentError)
            end
          end
        end
      end
    end
  end
end
