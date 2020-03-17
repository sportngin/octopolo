require "spec_helper"
require "octopolo/scripts/new_staging"

module Octopolo
  module Scripts
    describe NewStaging do
      subject { NewStaging.new }

      context "#execute" do
        it "delegates to DatedBranchCreator to create the branch with default delete flag" do
          expect(DatedBranchCreator).to receive(:perform).with(Git::STAGING_PREFIX, false)
          subject.execute
        end
        it "delegates to DatedBranchCreator to create the branch with delete flag" do
          expect(DatedBranchCreator).to receive(:perform).with(Git::STAGING_PREFIX, true)
          subject.execute(:delete_old_branches => true)
        end
      end
    end
  end
end

