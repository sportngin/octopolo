require "spec_helper"
require "octopolo/scripts/assign_team"
require "octopolo/github/label"

module Octopolo
  module Scripts
    describe AssignTeam do
      let(:label0) {stub(:Label, name: "Team Funny", color: "400000")}
      let(:label1) {stub(:Label, name: "Team Happy", color: "343434")}
      let(:label2) {stub(:Label, name: "Team Joyous", color: "565656")}
      let(:label3) {stub(:Label, name: "high-risk", color: "812456")}
      let(:config) {stub(:config, :github_repo => "tstmedia/foo", :deploy_branch => "master")}
      let(:cli) {stub}
      subject {AssignTeam.new}

      before do
        subject.config = config
        subject.cli = cli
      end

      context "Repo and teams are present" do
        it "should ask the user to select a team" do
          cli.should_receive(:ask).with("Assign yourself to which team?", ["Team Funny", "Team Happy", "Team Joyous"])
          allow(Octopolo::UserConfig).to receive(:set)
          allow(Octopolo::GitHub::Label).to receive(:all_from_repo).and_return([label0, label1, label2, label3])
          allow(config).to receive(:config_exists?).and_return(true)
          subject.execute
        end
      end

      context "Repo is present, but no teams are present" do
        it "should ask the user to type in a team" do
          cli.should_receive(:prompt).with("Please type in your team name: ").and_return("Jolly")
          allow(Octopolo::GitHub::Label).to receive(:all_from_repo).and_return([label3])
          allow(Octopolo::GitHub::Label).to receive(:first_or_create)
          allow(Octopolo::UserConfig).to receive(:set)
          allow(config).to receive(:config_exists?).and_return(true)
          subject.execute
        end
      end

      context "Repo is not present" do
        it "should ask the user to type in a team" do
          cli.should_receive(:prompt).with("Please type in your team name: ").and_return("Jolly")
          allow(Octopolo::UserConfig).to receive(:set)
          allow(config).to receive(:config_exists?).and_return(false)
          subject.execute
        end
      end
    end
  end
end
