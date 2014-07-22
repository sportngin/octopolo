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
    end
  end
end
