require "spec_helper"
require "octopolo/scripts/deployable"

module Octopolo
  module Scripts
    describe Deployable do
      let(:pull_request_id) { 42 }

      subject { Deployable.new '' }

      context "#execute" do
        before do
          subject.pull_request_id = pull_request_id
        end

        it "delegates the work to PullRequestMerger" do
          PullRequestMerger.should_receive(:perform).with(Git::DEPLOYABLE_PREFIX, 42, { notify_automation: true })
          subject.execute
        end
      end
    end
  end
end
