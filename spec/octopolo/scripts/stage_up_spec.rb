require "spec_helper"
require "octopolo/scripts/stage_up"

module Octopolo
  module Scripts
    describe StageUp do
      let(:pull_request_id) { 42 }

      subject { StageUp.new '' }

      context "#execute" do
        before do
          subject.pull_request_id = pull_request_id
        end

        it "delegates the work to PullRequestMerger" do
          PullRequestMerger.should_receive(:perform).with(Git::STAGING_PREFIX, 42)
          subject.execute
        end
      end
    end
  end
end

