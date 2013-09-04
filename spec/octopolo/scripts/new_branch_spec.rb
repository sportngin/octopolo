require "spec_helper"
require "automation/scripts/new_branch"

module Automation
  module Scripts
    describe NewBranch do
      let(:config) { stub(:config, :deploy_branch => "production") }
      let(:git) { stub(:Git) }
      let(:new_branch_name) { stub(:string) }
      let(:custom_source_branch) { stub(:string) }

      subject { NewBranch.new '' }

      before do
        subject.config = config
        subject.git = git
      end

      context "#parse" do
        it "fails if given no arguments" do
          expect { subject.parse([]) }.to raise_error(Clamp::UsageError)
        end

        it "accepts the first argument as the branch name" do
          subject.parse([new_branch_name])
          subject.new_branch_name.should == new_branch_name
          subject.source_branch_name.should == config.deploy_branch
        end

        it "accepts the second argument, if given, as the source to branch from" do
          subject.parse([new_branch_name, custom_source_branch])
          subject.new_branch_name.should == new_branch_name
          subject.source_branch_name.should == custom_source_branch
        end
      end

      context "#execute" do
        before do
          subject.new_branch_name = new_branch_name
          subject.source_branch_name = custom_source_branch
        end

        it "delegates to Git.new_branch" do
          git.should_receive(:new_branch).with(new_branch_name, custom_source_branch)
          subject.execute
        end
      end
    end
  end
end
