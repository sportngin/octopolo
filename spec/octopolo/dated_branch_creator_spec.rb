require "spec_helper"
require_relative "../../lib/octopolo/dated_branch_creator"

module Octopolo
  describe DatedBranchCreator do
    let(:type) { double(:string) }
    let(:branch_name) { double(:string) }
    let(:cli) { double(:CLI) }
    let(:config) { double(:Config, app_name: "fooapp", deploy_branch: "somebranch") }
    let(:git) { double(:Git) }

    subject { DatedBranchCreator.new type }

    before do
      subject.cli = cli
      subject.config = config
      subject.git = git
    end

    context ".perform(branch_type)" do
      let(:creator) { double(:DatedBranchCreator) }

      it "instantiates a new creator and performs it" do
        expect(DatedBranchCreator).to receive(:new).with(type, true) { creator }
        expect(creator).to receive(:perform)
        expect(DatedBranchCreator.perform(type, true)).to eq(creator)
      end
    end

    context ".new(branch_type)" do
      it "remembers the branch_type" do
        test = DatedBranchCreator.new(type)
        expect(test.branch_type).to eq(type)
      end
    end

    context "#perform" do
      it "creates the branch and handles cleaning up and posting about it" do
        expect(subject).to receive(:create_branch)
        expect(subject).to receive(:delete_old_branches)

        subject.perform
      end
    end

    context "#create_branch" do
      let(:runner) { double("script::new_branch") }

      before do
        allow(subject).to receive_messages(branch_name: branch_name)
      end

      it "creates a branch from its #branch_name" do
        expect(git).to receive(:new_branch).with(branch_name, config.deploy_branch)
        subject.create_branch
      end
    end

    context "#date_suffix" do
      it "uses today's date" do
        expect(subject.date_suffix).to eq(Date.today.strftime("%Y.%m.%d"))
      end
    end

    context "#branch_name" do
      it "properly generates a name for staging branches" do
        subject.branch_type = Git::STAGING_PREFIX
        expect(subject.branch_name).to eq("#{Git::STAGING_PREFIX}.#{subject.date_suffix}")
      end

      it "properly generates a name for deployable branches" do
        subject.branch_type = Git::DEPLOYABLE_PREFIX
        expect(subject.branch_name).to eq("#{Git::DEPLOYABLE_PREFIX}.#{subject.date_suffix}")
      end

      it "properly generates a name for qaready branches" do
        subject.branch_type = Git::QAREADY_PREFIX
        expect(subject.branch_name).to eq("#{Git::QAREADY_PREFIX}.#{subject.date_suffix}")
      end

      it "raises an exception for other branch types" do
        subject.branch_type = "asdfasdfasdf"
        expect { subject.branch_name }.to raise_error(DatedBranchCreator::InvalidBranchType, "'#{subject.branch_type}' is not a valid branch type")
      end
    end

    context "#delete_old_branches" do
      it "does nothing if no extra branches" do
        allow(subject).to receive_messages(extra_branches: [])
        expect(cli).not_to receive(:ask_boolean)
        subject.delete_old_branches
      end

      context "having extra branches" do
        let(:extras) { %w(foo bar) }
        let(:message) { "Do you want to delete the old #{subject.branch_type} branch(es)? (#{extras.join(", ")})"}

        before do
          allow(subject).to receive_messages(extra_branches: extras)
        end

        it "deletes these branches if user opts to" do
          expect(cli).to receive(:ask_boolean).with(message) { true }
          extras.each do |extra|
            expect(Git).to receive(:delete_branch).with(extra)
          end
          subject.delete_old_branches
        end

        it "does nothing if user opts not to delete" do
          expect(cli).to receive(:ask_boolean).with(message) { false }
          expect(cli).not_to receive(:perform)
          subject.delete_old_branches
        end

        context "delete flag" do
          before do
            allow(subject).to receive_messages(extra_branches: extras)
            subject.should_delete_old_branches = true
          end

          it "deletes these branches non-interactively" do
            expect(cli).not_to receive(:ask_boolean).with(message)
            extras.each do |extra|
              expect(Git).to receive(:delete_branch).with(extra)
            end
            subject.delete_old_branches
          end
        end
      end
    end

    context "#extra_branches" do
      let(:extra_deployables) { %w(foo bar) }
      let(:extra_stagings) { %w(bing bang) }

      it "gets the correct list for staging branches" do
        subject.branch_type = Git::STAGING_PREFIX
        allow(Git).to receive(:branches_for).with(Git::STAGING_PREFIX) { extra_stagings + [subject.branch_name] }
        expect(subject.extra_branches).not_to include subject.branch_name
        expect(subject.extra_branches).to eq(extra_stagings)
      end

      it "gets the correct list for deployable branches" do
        subject.branch_type = Git::DEPLOYABLE_PREFIX
        allow(Git).to receive(:branches_for).with(Git::DEPLOYABLE_PREFIX) { extra_deployables + [subject.branch_name] }
        expect(subject.extra_branches).not_to include subject.branch_name
        expect(subject.extra_branches).to eq(extra_deployables)
      end

      it "raises an exception for any other branch type" do
        subject.branch_type = "asdfasdfasdf"
        expect { subject.extra_branches }.to raise_error(DatedBranchCreator::InvalidBranchType, "'#{subject.branch_type}' is not a valid branch type")
      end
  ; end

  end
end
