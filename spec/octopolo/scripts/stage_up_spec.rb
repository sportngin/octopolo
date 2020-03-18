require "spec_helper"
require "octopolo/scripts/stage_up"

module Octopolo
  module Scripts
    describe StageUp do
      let(:cli) { double(:Cli) }
      before { allow_any_instance_of(StageUp).to receive_messages(:cli => cli) }

      context "#execute" do
        context "with a PR passed in via the command args" do
          subject { StageUp.new 42 }

          it "delegates the work to PullRequestMerger" do
            expect(PullRequestMerger).to receive(:perform).with(Git::STAGING_PREFIX, 42)
            subject.execute
          end
        end

        context "with no PR passed in from the command args" do
          subject { StageUp.new }

          context "with an existing PR for the current branch" do
            before do
              expect(GitHub::PullRequest).to receive(:current) { GitHub::PullRequest.new("account/repo", 7) }
            end

            it "takes the pull requests ID from the current branch" do
              expect(PullRequestMerger).to receive(:perform).with(Git::STAGING_PREFIX, 7)
              subject.execute
            end
          end

          context "without an existing PR for the current branch" do
            before do
              expect(GitHub::PullRequest).to receive(:current) { nil }
            end

            context "with a PR passed in through the cli" do
              before do
                expect(cli).to receive(:prompt)
                   .with("Pull Request ID: ")
                   .and_return("42")
              end

              it "delegates the work to PullRequestMerger" do
                expect(PullRequestMerger).to receive(:perform).with(Git::STAGING_PREFIX, 42)
                subject.execute
              end
            end

            context "with no PR passed in from the cli" do
              before do
                expect(cli).to receive(:prompt)
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
end

