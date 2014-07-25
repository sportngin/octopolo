require "spec_helper"
require "octopolo/scripts/deployable"

module Octopolo
  module Scripts
    describe Deployable do
      let(:cli) { stub(:Cli) }
      let(:config) { stub(:user_notifications => ['NickLaMuro'], :github_repo => 'foo', :deployable_label => true) }
      before { Deployable.any_instance.stub(:cli => cli, :config => config) }

      context "#execute" do
        subject { Deployable.new 42}
        it "calls merge_and_label" do
          expect(subject).to receive(:merge_and_label)
          subject.execute
        end

        context "#merge_and_label" do
          before do
            allow(PullRequestMerger).to receive(:perform)
          end

          context "deployable_label is set to true" do
            it "calls ensure_label_was_created" do
              expect(subject).to receive(:ensure_label_was_created)
              subject.execute
            end
          end

          context "deployable_label is set to false " do 
            let(:config) { stub(:user_notifications => ['NickLaMuro'], :github_repo => 'foo', :deployable_label => false) }
            it "skips add_to_pull when deployable_label is false" do
              expect(subject).to_not receive(:ensure_label_was_created)
              subject.execute
            end
          end
        end
      end

      context "#ensure_label_was_created" do
        subject { Deployable.new 42}
        let(:pull_request) {Octopolo::GitHub::PullRequest.new('foo', subject.pull_request_id, nil)}
        before do
          allow_any_instance_of(Octopolo::GitHub::PullRequest).to receive(:add_labels)
        end

        context "with a PR passed in via the command args" do
          it "delegates the work to PullRequestMerger" do
            expect(PullRequestMerger).to receive(:perform).with(Git::DEPLOYABLE_PREFIX, 42, :user_notifications => ["NickLaMuro"]) {true}
            subject.ensure_label_was_created
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
              expect(PullRequestMerger).to receive(:perform).with(Git::DEPLOYABLE_PREFIX, 42, :user_notifications => ["NickLaMuro"]) {true}
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

        context "when it creates a label successfully" do

          it "calls remove_label when pull_request_merge fails" do
            allow(PullRequestMerger).to receive(:perform) {nil}
            expect_any_instance_of(Octopolo::GitHub::PullRequest).to receive(:remove_labels)
            subject.ensure_label_was_created
          end
        end
      end
      
    end
  end
end
