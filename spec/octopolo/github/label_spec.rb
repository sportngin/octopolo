require "spec_helper"
require_relative "../../../lib/octopolo/github/label"

module Octopolo
  module GitHub
    describe Label do

      let(:label_hash_1) { {name: "low-risk", url: "github.com", color: "343434"} }
      let(:label_hash_2) { {name: "high-risk", url: "github.com", color: "565656"} }
      let(:labels_hash) { [label_hash_1,label_hash_2] }
      let(:config) { stub(:config, github_repo: "foo") }

      subject { Label }

      before do
        subject.config = config
      end

      context "#from_github" do
        it "gets and returns all labels belonging to a repository" do
          allow(GitHub).to receive(:labels).and_return(labels_hash)
          expect(Label.from_github()).to eq([{name: "low-risk", color: "343434"},{name: "high-risk", color: '565656'}])
        end
      end

      context "#all_names" do
        it "gets and returns all labels names belonging to a repository" do
          allow(GitHub).to receive(:labels).and_return(labels_hash)
          expect(Label.all_names).to eq(["low-risk","high-risk"])
        end
      end

      context "#first_or_create" do
        it "finds the existing label and doesn't do anything" do
          allow(Label).to receive(:all_names).and_return(["low-risk","high-risk"])
          expect(GitHub).not_to receive(:labels)
          Label.first_or_create("low-risk", "565656")
        end

        it "doesn't find a label and creates one" do
          allow(Label).to receive(:all_names).and_return(["low-risk","high-risk"])
          expect(GitHub).to receive(:labels).with(config.github_repo, "medium-risk", "454545")
          Label.first_or_create("medium-risk", "454545")
        end
      end
    end
  end
end
