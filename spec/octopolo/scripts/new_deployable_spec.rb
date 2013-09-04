require "spec_helper"
require "automation/scripts/new_deployable"

module Automation
  module Scripts
    describe NewDeployable do
      subject { NewDeployable.new '' }

      context "#execute" do
        it "delegates the work to DatedBranchCreator" do
          DatedBranchCreator.should_receive(:perform).with(Git::DEPLOYABLE_PREFIX)
          subject.execute
        end
      end
    end
  end
end

