require "spec_helper"
require "automation/scripts/accept_pull"

module Automation
  module Scripts
    describe AcceptPull do
      let(:config) { stub(:config, :github_repo => "tstmedia/foo") }
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
          subject.should_receive(:write_json).with(pull_request)

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

        context "when mergeable" do
          before { pull_request.stub(mergeable?: true) }

          it "fetches and merges the request's branch" do
            Git.should_receive(:fetch)
            cli.should_receive(:perform).with "git merge --no-ff origin/#{pull_request.branch}"

            subject.merge pull_request
          end
        end

        context "when not mergeable" do
          before { pull_request.stub(mergeable?: false) }

          it "performs the merge and alerts about potential failures" do
            Git.should_receive(:fetch)
            cli.should_receive(:perform).with "git merge --no-ff origin/#{pull_request.branch}"

            cli.should_receive(:say).with "\n=====ATTENTION====="
            cli.should_receive(:say).with "There was a conflict with the merge. Either fix the conflicts and commit, or abort the merge with"
            cli.should_receive(:say).with "    'git merge --abort'"
            cli.should_receive(:say).with "and remove this entry from CHANGELOG.markdown\n"

            subject.merge pull_request
          end
        end
      end

      context "#write_json" do
        let(:pull_request) { stub }

        it "writes the pull request for Zapier" do
          Zapier.should_receive(:encode).with(pull_request)
          subject.write_json pull_request
        end
      end

    end
  end
end
