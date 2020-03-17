require "spec_helper"
require "octopolo/scripts/new_branch"

module Octopolo
  module Scripts
    describe NewBranch do
      let(:config) { double(:config, :deploy_branch => "production") }
      let(:git) { double(:Git) }
      let(:cli) { double(:Cli) }
      let(:new_branch_name) { double(:string) }
      let(:custom_source_branch) { double(:string) }

      subject { NewBranch }

      before do
        allow_any_instance_of(NewBranch).to receive_messages(:config => config, :git => git, :cli => cli)
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
            expect(git).to receive(:alert_reserved_branch)
            expect { subject.execute(new_branch_name) }.to raise_error(SystemExit)
          end

          it "proceeds when confirmed" do
            allow(git).to receive(:reserved_branch?) { true }
            allow(cli).to receive(:ask_boolean) { true }
            allow(cli).to receive(:say).with(anything)
            expect(git).to receive(:new_branch).with(new_branch_name, "production")
            subject.execute(new_branch_name)
          end
        end

        context "with only new branch name given" do
          it "delegates to Git.new_branch" do
            allow(git).to receive(:reserved_branch?) { false }
            expect(git).to receive(:new_branch).with(new_branch_name, "production")
            subject.execute(new_branch_name)
          end
        end

        context "with new and source branch names given" do
          it "delegates to Git.new_branch" do
            allow(git).to receive(:reserved_branch?) { false }
            expect(git).to receive(:new_branch).with(new_branch_name, custom_source_branch)
            subject.execute(new_branch_name, custom_source_branch)
          end
        end
      end
    end
  end
end
