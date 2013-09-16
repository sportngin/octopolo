require "spec_helper"
require_relative "../../../lib/octopolo/zapier/branch_poster"

module Octopolo
  module Zapier
    describe BranchPoster do
      let(:poster) { BranchPoster.new application_name, branch_name, branch_type }
      let(:branch_type) { "deployable" }
      let(:branch_name) { "deployable.10.17" }
      let(:application_name) { "ngin" }
      let(:message) { "asdf" }

      context ".perform(application_name, branch_name, branch_type)" do
        let(:poster) { stub }

        it "instantates a new poster and performs it" do
          BranchPoster.should_receive(:new).with(application_name, branch_name, branch_type) { poster }
          poster.should_receive(:perform)
          BranchPoster.perform(application_name, branch_name, branch_type).should == poster
        end
      end

      context ".new application_name, branch_name, branch_type" do
        it "remembers the apllication and branch names" do
          poster = BranchPoster.new application_name, branch_name, branch_type
          poster.branch_name.should == branch_name
          poster.branch_type.should == branch_type
          poster.application_name.should == application_name
        end
      end

      context "#perform" do
        let(:curl) { %Q(curl -H 'Content-Type: application/json' -X POST -d '{"message": "#{message}"}' '#{Zapier.endpoint Zapier::MESSAGE_TO_DEVO}') }

        before do
          poster.stub(message: message)
        end

        it "posts to campfire that the the branche's message" do
          Octopolo::CLI.should_receive(:perform_quietly).with(curl)
          poster.perform
        end
      end

      context "#message" do
        it "includes relevant details for a deployable branch" do
          poster.branch_type = Git::DEPLOYABLE_PREFIX
          poster.message.should include "A new #{poster.branch_type} branch (#{branch_name}) has been created for #{application_name}."
          poster.message.should include "please re-merge with the `deployable` command"
        end

        it "includes relevant details for a staging branch" do
          poster.branch_type = Git::STAGING_PREFIX
          poster.message.should include "A new #{poster.branch_type} branch (#{branch_name}) has been created for #{application_name}."
          poster.message.should include "please re-merge with the `stage-up` command"
        end
      end
    end
  end
end
