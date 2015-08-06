require "spec_helper"
require "octopolo/scripts/accept_pull"

module Octopolo
  module Scripts
    describe AcceptPull do
      let(:config) { stub(:config, :github_repo => "tstmedia/foo", :deploy_branch => "master") }
      let(:cli) { stub }
      let(:git) { stub(:Git) }
      let(:pull_request) { stub(:PullRequest, branch: "cool-feature", url: "http://example.com/", mergeable?: true) }

      subject { AcceptPull.new(pull_request_ids) }

      before do
        subject.git = git
        subject.config = config
        subject.cli = cli
      end

      describe "#execute" do
        before do
          GitHub.should_receive(:connect).and_yield
          Git.should_receive(:fetch)
        end

        context "with one PR ID" do
          let(:pull_request_ids) { 42 }

          it "merges the change and updates the changelog" do
            GitHub::PullRequest.should_receive(:new).with(config.github_repo, pull_request_ids) { pull_request }
            subject.should_receive(:perform_merge)
            subject.should_receive(:update_changelog).with(pull_request)

            subject.execute
          end

          context "when the pull request is not found" do
            it "does not merge or update the changelog" do
              GitHub::PullRequest.should_receive(:new) { raise(GitHub::Issue::NotFound) }
              subject.should_receive(:perform_merge).never
              subject.should_receive(:update_changelog).never

              cli.should_receive(:say).with("Unable to find a pull request ##{pull_request_ids} for #{config.github_repo}. Please verify.")
              subject.should_receive(:exit).with(1)

              subject.execute
            end
          end
        end

        context "with multiple PR IDs" do
          let(:pull_request_ids) { [1,2,3] }

          it "merges the changes and updates the changelog" do
            pull_request_ids.each do |id|
              GitHub::PullRequest.should_receive(:new).with(config.github_repo, id) { pull_request }
            end
            subject.should_receive(:perform_merge).exactly(3).times
            subject.should_receive(:update_changelog).with(pull_request).exactly(3).times

            subject.execute
          end
        end
      end
    end
  end
end
