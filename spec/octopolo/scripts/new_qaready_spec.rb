require "spec_helper"
require "automation/scripts/new_qaready"

module Automation
  module Scripts
    describe NewQaready do

      subject { NewQaready.new '' }

      context "#execute" do
        it "creates a new QA-ready branch" do
          DatedBranchCreator.should_receive(:perform).with(Git::QAREADY_PREFIX)
          subject.execute
        end
      end
    end
  end
end

# vim: set ft=ruby : #
