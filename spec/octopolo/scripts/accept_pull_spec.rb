require "spec_helper"
require "octopolo/scripts/accept_pull"

module Octopolo
  module Scripts
    describe AcceptPull do
      let(:config) { double(:config, :github_repo => "tstmedia/foo", :deploy_branch => "master") }
      let(:cli) { double }
      let(:git) { double(:Git) }
      let(:pull_request_id) { 42 }
      let(:pull_request) { double(:PullRequest, branch: "cool-feature", url: "http://example.com/") }

      subject { AcceptPull.new '' }

      before do
        subject.git = git
        subject.config = config
        subject.cli = cli
      end

      context "#execute" do
        before do
          subject.pull_request_id = pull_request_id
        end

        it "merges the change and updates the changelog" do
          expect(GitHub).to receive(:connect).and_yield
          expect(GitHub::PullRequest).to receive(:new).with(config.github_repo, pull_request_id) { pull_request }
          expect(subject).to receive(:merge).with(pull_request)
          expect(subject).to receive(:update_changelog).with(pull_request)

          subject.execute
        end

        it "does not if given an invalid pull request number" do
          expect(GitHub).to receive(:connect).and_yield
          expect(GitHub::PullRequest).to receive(:new).and_raise(GitHub::PullRequest::NotFound)
          expect(subject).to receive(:merge).never
          expect(subject).to receive(:update_changelog).never
          expect(cli).to receive(:say).with("Unable to find a pull request #{pull_request_id} for #{config.github_repo}. Please verify.")

          subject.execute
        end
      end

      context "#merge" do
        let(:pull_request) { double(branch: "foobranch") }
        before { allow(subject).to receive_messages(:pull_request_id => pull_request_id) }

        context "when mergeable and status checks passed" do
          before { allow(pull_request).to receive_messages(mergeable?: true, status_checks_passed?: true) }

          it "fetches and merges the request's branch" do
            expect(Git).to receive(:fetch)
            expect(cli).to receive(:perform).with "git merge --no-ff origin/#{pull_request.branch} -m \"Merge pull request ##{pull_request_id} from origin/#{pull_request.branch}\""

            subject.merge pull_request
          end
        end

        context "when not mergeable" do
          before do
            allow(pull_request).to receive_messages(mergeable?: false)
            allow(subject).to receive(:exit!)
          end

          it "performs the merge and alerts about potential failures" do
            expect(Git).to receive(:fetch)
            allow(cli).to receive(:say)
            expect(cli).not_to receive(:perform).with "git merge --no-ff origin/#{pull_request.branch} -m \"Merge pull request ##{pull_request_id} from origin/#{pull_request.branch}\""

            expect(cli).to receive(:say).with /merge conflict/
            expect(subject).to receive(:exit!)
            subject.merge pull_request
          end
        end

        context "when mergeable and status checks have not passed" do
          before do
            allow(pull_request).to receive_messages(mergeable?: true, status_checks_passed?: false)
            allow(subject).to receive(:exit!)
          end

          it "performs the merge and alerts about potential failures" do
            expect(Git).to receive(:fetch)
            allow(cli).to receive(:say)
            expect(cli).not_to receive(:perform).with "git merge --no-ff origin/#{pull_request.branch} -m \"Merge pull request ##{pull_request_id} from origin/#{pull_request.branch}\""

            expect(cli).to receive(:say).with 'Previous action not completed. Status checks have not passed on this pull request.'
            expect(subject).to receive(:exit!)
            subject.merge pull_request
          end
        end

        context "when failed status checks should be ignored" do
          subject { described_class.new(pull_request_id, force: true) }
          before { allow(pull_request).to receive_messages(mergeable?: true, status_checks_passed?: false) }

          it "fetches and merges the request's branch" do
            expect(Git).to receive(:fetch)
            expect(cli).to receive(:perform).with "git merge --no-ff origin/#{pull_request.branch} -m \"Merge pull request ##{pull_request_id} from origin/#{pull_request.branch}\""

            subject.merge pull_request
          end
        end
      end
    end
  end
end
