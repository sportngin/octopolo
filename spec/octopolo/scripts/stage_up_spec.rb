require "spec_helper"
require "octopolo/scripts/stage_up"

module Octopolo
  module Scripts
    describe StageUp do
      let(:cli) { stub(:Cli) }
      before { StageUp.any_instance.stub(:cli => cli) }

      context "#execute" do
        context "with a PR passed in via the command args" do
          subject { StageUp.new 42 }

          it "delegates the work to PullRequestMerger" do
            PullRequestMerger.should_receive(:perform).with(Git::STAGING_PREFIX, 42)
            subject.execute
          end
        end

        context "with no PR passed in from the command args" do
          subject { StageUp.new }

          context "with an existing PR for the current branch" do
            before do
              GitHub::PullRequest.should_receive(:current) { GitHub::PullRequest.new("account/repo", 7) }
            end

            it "takes the pull requests ID from the current branch" do
              PullRequestMerger.should_receive(:perform).with(Git::STAGING_PREFIX, 7)
              subject.execute
            end
          end

          context "without an existing PR for the current branch" do
            before do
              GitHub::PullRequest.should_receive(:current) { nil }
            end

            context "with a PR passed in through the cli" do
              before do
                cli.should_receive(:prompt)
                   .with("Pull Request ID: ")
                   .and_return("42")
              end

              it "delegates the work to PullRequestMerger" do
                PullRequestMerger.should_receive(:perform).with(Git::STAGING_PREFIX, 42)
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
end

