require "spec_helper"
require_relative "../../../lib/octopolo/scripts/new_staging"

module Octopolo
  module Scripts
    describe NewStaging do
      subject { NewStaging.new '' }

      context "#execute" do
        it "delegates to DatedBranchCreator to create the branch" do
          DatedBranchCreator.should_receive(:perform).with(Git::STAGING_PREFIX)
          subject.should_receive(:temporary_code_climate_warning)
          subject.execute
        end
      end

      context "#temporary_code_climate_warning" do
        let(:cli) { stub(:cli) }

        before do
          subject.cli = cli
        end

        it "warns that the project needs to be set up again in Code Climate" do
          cli.should_receive(:say).with "NOTE: This project likely needs to be set up again in Code Climate. Please work with Infrastructure to get this done."
          subject.send(:temporary_code_climate_warning)
        end
      end
    end
  end
end

