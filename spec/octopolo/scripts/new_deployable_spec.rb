require "spec_helper"
require "octopolo/scripts/new_deployable"

module Octopolo
  module Scripts
    describe NewDeployable do
      subject { NewDeployable.new }

      context "#execute" do
        it "delegates the work to DatedBranchCreator with default delete flag" do
          expect(DatedBranchCreator).to receive(:perform).with(Git::DEPLOYABLE_PREFIX, false)
          subject.execute
        end
        it "delegates the work to DatedBranchCreator with delete flag" do
          expect(DatedBranchCreator).to receive(:perform).with(Git::DEPLOYABLE_PREFIX, true)
          subject.execute(:delete_old_branches => true)
        end
      end
    end
  end
end

