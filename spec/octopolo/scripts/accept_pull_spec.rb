require "spec_helper"
require "octopolo/scripts/accept_pull"

module Octopolo
  module Scripts
    describe AcceptPull do
      let(:config) { stub(:config, :github_repo => "tstmedia/foo", :deploy_branch => "master") }
      let(:cli) { stub }
      let(:git) { stub(:Git) }
      let(:pull_request_id) { 42 }
      let(:pull_request) { stub(:PullRequest, branch: "cool-feature", url: "http://example.com/") }

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
          GitHub.should_receive(:connect).and_yield
          GitHub::PullRequest.should_receive(:new).with(config.github_repo, pull_request_id) { pull_request }
          subject.should_receive(:merge).with(pull_request)
          subject.should_receive(:update_changelog).with(pull_request)

          subject.execute
        end

        it "does not if given an invalid pull request number" do
          GitHub.should_receive(:connect).and_yield
          GitHub::PullRequest.should_receive(:new).and_raise(GitHub::PullRequest::NotFound)
          subject.should_receive(:merge).never
          subject.should_receive(:update_changelog).never
          cli.should_receive(:say).with("Unable to find a pull request #{pull_request_id} for #{config.github_repo}. Please verify.")

          subject.execute
        end
      end

      context "#merge" do
        let(:pull_request) { stub(branch: "foobranch") }
        before { subject.stub(:pull_request_id => pull_request_id) }

        context "when mergeable" do
          before { pull_request.stub(mergeable?: true) }

          it "fetches and merges the request's branch" do
            Git.should_receive(:fetch)
            cli.should_receive(:perform).with "git merge --no-ff origin/#{pull_request.branch} -m \"Merge pull request ##{pull_request_id} from origin/#{pull_request.branch}\""

            subject.merge pull_request
          end
        end

        context "when not mergeable" do
          before { pull_request.stub(mergeable?: false) }

          it "performs the merge and alerts about potential failures" do
            Git.should_receive(:fetch)
            cli.stub(:say)
            cli.should_not_receive(:perform).with "git merge --no-ff origin/#{pull_request.branch} -m \"Merge pull request ##{pull_request_id} from origin/#{pull_request.branch}\""

            cli.should_receive(:say).with /merge conflict/
            subject.merge pull_request
          end
        end
      end
    end
  end
end
