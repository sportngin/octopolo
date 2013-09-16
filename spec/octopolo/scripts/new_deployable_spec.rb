require "spec_helper"
require_relative "../../../lib/octopolo/scripts/new_deployable"

module Octopolo
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

