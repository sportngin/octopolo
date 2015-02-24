require "spec_helper"
require "octopolo/scripts/deployable"

module Octopolo
  module Scripts
    describe Deployable do
      subject { described_class.new 42 }

      let(:cli) { stub(prompt: 42) }
      let(:config) { stub(user_notifications: ['NickLaMuro'],
                          github_repo: 'grumpy_cat',
                          deployable_label: true) }
      let(:pull_request) { stub(add_labels: true, remove_labels: true) }
      before do
        allow(subject).to receive(:cli) { cli }
        allow(subject).to receive(:config) { config }
        allow(Octopolo::GitHub::PullRequest).to receive(:new) { pull_request }
        allow(PullRequestMerger).to receive(:perform) { true }
      end

      context "#execute" do
        after do
          subject.execute
        end

        context "with a PR ID passed in with the command" do
          it "doesn't prompt for a PR ID" do
            cli.should_not_receive(:prompt)
          end
        end

        context "without a PR ID passed in with the command" do
          subject { described_class.new }

          it "prompts for a PR ID" do
            cli.should_receive(:prompt)
              .with("Pull Request ID: ")
              .and_return("42")
          end
        end

        context "with labelling enabled" do
          it "adds the deployable label" do
            pull_request.should_receive(:add_labels)
          end

          context "when merge to deployable fails" do
            before do
              allow(PullRequestMerger).to receive(:perform) { false }
            end

            it "removes the deployable label" do
              pull_request.should_receive(:remove_labels)
            end
          end

          context "when the merge to deployable succeeds" do
            it "doesn't remove the deployable label" do
              pull_request.should_not_receive(:remove_labels)
            end
          end
        end

        context "with labelling disabled" do
          let(:config) { stub(user_notifications: ['NickLaMuro'],
                              github_repo: 'grumpy_cat',
                              deployable_label: false) }

          it "doesn't add the deployable label" do
            pull_request.should_not_receive(:add_labels)
          end
        end
      end
    end
  end
end
