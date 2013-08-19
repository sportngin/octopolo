require "spec_helper"
require_relative "../../../lib/octopolo/scripts/push_branch"

module Octopolo
  module Scripts
    describe PushBranch do
      let(:git) { stub(:Git, current_branch: "foo") }

      subject { PushBranch.new '' }

      before do
        subject.git = git
      end

      context "#execute" do
        it "pushes the current branch and ensures that the upstream is set" do
          git.should_receive(:perform).with("push --set-upstream origin #{git.current_branch}")
          subject.execute
        end
      end
    end
  end
end
