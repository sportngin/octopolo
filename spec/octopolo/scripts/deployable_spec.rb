require "spec_helper"
require "octopolo/scripts/deployable"

module Octopolo
  module Scripts
    describe Deployable do
      subject { described_class.new 42 }

      let(:cli) { double(prompt: 42) }
      let(:config) { double(user_notifications: ['NickLaMuro'],
                          github_repo: 'grumpy_cat',
                          deployable_label: true) }
      let(:pull_request) { double(add_labels: true,
                                remove_labels: true,
                                number: 7,
                                mergeable?: true,
                                status_checks_passed?: true) }
      before do
        allow(subject).to receive(:cli) { cli }
        allow(subject).to receive(:config) { config }
        allow(Octopolo::GitHub::PullRequest).to receive(:new) { pull_request }
        allow_any_instance_of(PullRequestMerger).to receive(:perform) { true }
        allow(Octopolo::GitHub).to receive(:check_connection) { true }
      end

      context "#execute" do
        after do
          subject.execute
        end

        context "with a PR ID passed in with the command" do
          it "doesn't prompt for a PR ID" do
            expect(cli).not_to receive(:prompt)
          end
        end

        context "without a PR ID passed in with the command" do
          subject { described_class.new }

          context "with an existing PR for the current branch" do
            before do
              expect(GitHub::PullRequest).to receive(:current) { pull_request }
            end

            it "takes the pull requests ID from the current branch" do
              expect_any_instance_of(PullRequestMerger).to receive(:perform)
            end
          end

          context "without an existing PR for the current branch" do
            before do
              expect(GitHub::PullRequest).to receive(:current) { nil }
            end

            it "prompts for a PR ID" do
              expect(cli).to receive(:prompt)
                .with("Pull Request ID: ")
                .and_return("42")
            end
          end
        end

        context "with labelling enabled" do
          it "adds the deployable label" do
            expect(pull_request).to receive(:add_labels)
          end

          context "when merge to deployable fails" do
            before do
              allow_any_instance_of(PullRequestMerger).to receive(:perform) { false }
            end

            it "does not add any labels" do
              expect(pull_request).not_to receive(:add_labels)
            end
          end

          context "when the merge to deployable succeeds" do
            it "adds a label" do
              expect(pull_request).to receive(:add_labels)
            end
          end

          context "with an invalid auth token" do
            before do
              allow(Octopolo::GitHub).to receive(:check_connection) { raise GitHub::BadCredentials, "Your stored credentials were rejected by GitHub. Run `op github-auth` to generate a new token." }
            end

            it "should give a helpful error message saying your token is invalid" do
              expect(CLI).to receive(:say).with("Your stored credentials were rejected by GitHub. Run `op github-auth` to generate a new token.")
            end
          end
        end

        context "with labelling disabled" do
          let(:config) { double(user_notifications: ['NickLaMuro'],
                              github_repo: 'grumpy_cat',
                              deployable_label: false) }

          it "doesn't add the deployable label" do
            expect(pull_request).not_to receive(:add_labels)
          end
        end

        context "when pr is not mergeable" do
          before do
            allow(pull_request).to receive_messages(mergeable?: false)
            allow(subject).to receive(:exit!)
          end

          it "prints out an error and exits" do
            expect(CLI).to receive(:say).with("Pull request status checks have not passed. Cannot be marked deployable.")
            expect(subject).to receive(:exit!)
          end
        end

        context "when pr has not passed status checks" do
          before do
            allow(pull_request).to receive_messages(status_checks_passed?: false)
            allow(subject).to receive(:exit!)
          end

          it "prints out an error and exits" do
            expect(CLI).to receive(:say).with("Pull request status checks have not passed. Cannot be marked deployable.")
            expect(subject).to receive(:exit!)
          end
        end

        context "when failed status checks should be ignored" do
          subject { described_class.new(42, force: true) }
          before { allow(pull_request).to receive_messages(status_checks_passed?: false) }

          it "adds the deployable label" do
            expect(pull_request).to receive(:add_labels)
          end
        end
      end
    end
  end
end
