require "spec_helper"
require "octopolo/scripts/new_staging"

module Octopolo
  module Scripts
    describe NewStaging do
      subject { NewStaging.new }

      context "#execute" do
        it "delegates to DatedBranchCreator to create the branch" do
          DatedBranchCreator.should_receive(:perform).with(Git::STAGING_PREFIX)
          subject.execute
        end
      end
    end
  end
end

