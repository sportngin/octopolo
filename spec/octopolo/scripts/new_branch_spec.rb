require "spec_helper"
require "octopolo/scripts/new_branch"

module Octopolo
  module Scripts
    describe NewBranch do
      let(:config) { stub(:config, :deploy_branch => "production") }
      let(:git) { stub(:Git) }
      let(:cli) { stub(:Cli) }
      let(:new_branch_name) { stub(:string) }
      let(:custom_source_branch) { stub(:string) }

      subject { NewBranch }

      before do
        NewBranch.any_instance.stub(:config => config, :git => git, :cli => cli)
      end

      context "::execute" do
        context "with no arguments given" do
          it "fails if given no arguments" do
            expect { subject.execute }.to raise_error(ArgumentError)
          end
        end


        context "with reserved new branch name" do
          it "exits when aborted" do
            allow(git).to receive(:reserved_branch?) { true }
            allow(cli).to receive(:ask_boolean) { false }
            allow(cli).to receive(:say).with(anything)
            git.should_receive(:alert_reserved_branch)
            expect { subject.execute(new_branch_name) }.to raise_error(SystemExit)
          end

          it "proceeds when confirmed" do
            allow(git).to receive(:reserved_branch?) { true }
            allow(cli).to receive(:ask_boolean) { true }
            allow(cli).to receive(:say).with(anything)
            git.should_receive(:new_branch).with(new_branch_name, "production")
            subject.execute(new_branch_name)
          end
        end

        context "with only new branch name given" do
          it "delegates to Git.new_branch" do
            allow(git).to receive(:reserved_branch?) { false }
            git.should_receive(:new_branch).with(new_branch_name, "production")
            subject.execute(new_branch_name)
          end
        end

        context "with new and source branch names given" do
          it "delegates to Git.new_branch" do
            allow(git).to receive(:reserved_branch?) { false }
            git.should_receive(:new_branch).with(new_branch_name, custom_source_branch)
            subject.execute(new_branch_name, custom_source_branch)
          end
        end
      end
    end
  end
end
