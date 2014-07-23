require "spec_helper"
require_relative "../../../lib/octopolo/github/label"

module Octopolo
  module GitHub
    describe Label do

      let(:label_hash_1) { {name: "low-risk", url: "github.com", color: "343434"} }
      let(:label_hash_2) { {name: "high-risk", url: "github.com", color: "565656"} }
      let(:labels_hash) { [label_hash_1,label_hash_2] }
      let(:label1) { Label.new("low-risk", "343434") }
      let(:label2) { Label.new("high-risk", '565656') }
      let(:config) { stub(:config, github_repo: "foo") }

      subject { Label }

      before do
        subject.config = config
      end

      context "#all_labels" do
        it "gets and returns all labels belonging to a repository" do
          allow(GitHub).to receive(:labels).and_return(labels_hash)
          expect(Label.all_labels).to eq([label1,label2])
        end
      end

      context "#first_or_create" do
        it "finds the existing label and doesn't do anything" do
          allow(Label).to receive(:all_labels).and_return([label1,label2])
          expect(GitHub).not_to receive(:add_label)
          Label.first_or_create(label1)
        end

        it "doesn't find a label and creates one" do
          allow(Label).to receive(:all_labels).and_return([label1,label2])
          expect(GitHub).to receive(:add_label).with(config.github_repo, "medium-risk", "454545")
          Label.first_or_create(Label.new("medium-risk","454545"))
        end
      end

      context "#to_label" do 
        it "returns a label object" do
          expect(Label).to receive(:new)
          Label.send(:to_label, label_hash_1)
        end
      end

      context "#==" do
        it "returns true if names are same ignoring color" do
          expect(label1 == Label.new("low-risk","121212")).to eq(true)
        end

        it "returns true if names are same ignoring color" do
          expect(label1 == label2).to eq(false)
        end
      end

      context "#add_to_pull" do
        let (:pull_number) {007}
        it "sends the correct arguments to add_labels_to_pull for multiple labels" do
          allow(Label).to receive(:first_or_create)
          expect(GitHub).to receive(:add_labels_to_pull).with(config.github_repo, pull_number, ["low-risk","high-risk"])
          Label.add_to_pull(pull_number,[label1, label2])
        end

        it "sends the correct arguments to add_labels_to_pull for a single label" do
          allow(Label).to receive(:first_or_create)
          expect(GitHub).to receive(:add_labels_to_pull).with(config.github_repo, pull_number, ["low-risk"])
          Label.add_to_pull(pull_number,label1)
        end
      end 

      context "#build_labels" do 
        it "returns an array of label when given a label" do
          allow(Label).to receive(:first_or_create)
          expect(Label.send(:build_label_array,label1)).to eq([label1])
        end

        it "returns an array of labels when given a list of labels" do
          allow(Label).to receive(:first_or_create)
          expect(Label.send(:build_label_array,label1,label2)).to eq([label1,label2])
        end

        it "returns an array of labels when given an array of length 1" do
          allow(Label).to receive(:first_or_create)
          expect(Label.send(:build_label_array,[label1])).to eq([label1])
        end

        it "returns an array of labels when given an array of length 1" do
          allow(Label).to receive(:first_or_create)
          expect(Label.send(:build_label_array,[label1,label2])).to eq([label1,label2])
        end
      end

      context "#get_names" do
        it "returns a list of names when given an array of labels" do
          expect(Label.get_names([label1,label2])).to eq(["low-risk","high-risk"])
        end
      end
    end
  end
end
