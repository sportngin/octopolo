require "spec_helper"
require_relative "../../../lib/octopolo/github"

module Octopolo
  module GitHub
    describe Label do

      let(:label_hash_1) { {name: "low-risk", url: "github.com", color: "343434"} }
      let(:label_hash_2) { {name: "high-risk", url: "github.com", color: "565656"} }
      let(:labels_hash) { [label_hash_1,label_hash_2] }
      let(:label1) { Label.new(name: "low-risk", color: "343434") }
      let(:label2) { Label.new(name: "high-risk", color: '565656') }
      let(:config) { stub(:config, github_repo: "foo") }

      subject { Label }

      before do
        subject.config = config 
        allow(GitHub).to receive(:labels).with(config.github_repo, page: 1).and_return(labels_hash)
        allow(GitHub).to receive(:labels).with(config.github_repo, page: 2).and_return([])
      end

      context "#initialize" do
        it "creates a label from a hash" do
          expect(Label.new(name: "low", color: "151515").name).to eq('low')
        end
      end


      context "#all_labels" do
        it "gets and returns all labels belonging to a repository" do
          expect(Label.all).to eq([label1,label2])
        end
      end

      context "#first_or_create" do
        it "finds the existing label and doesn't do anything" do
          expect(GitHub).not_to receive(:add_label)
          Label.first_or_create(label1)
        end

        it "doesn't find a label and creates one" do
          expect(GitHub).to receive(:add_label).with(config.github_repo, "medium-risk", "454545")
          Label.first_or_create(Label.new(name: "medium-risk", color: "454545"))
        end
      end

      context "#==" do
        it "returns true if names are same ignoring color" do
          expect(label1 == Label.new(name: "low-risk",color: "121212")).to eq(true)
        end

        it "returns true if names are same ignoring color" do
          expect(label1 == label2).to eq(false)
        end
      end

      context "#build_label_array" do
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

      describe "#all_from_repo" do
        context "when there is only one page of labels" do
          it "should go through the paginated list of repos" do
            expect(Label.send(:all_from_repo)).to eq([label1, label2])
          end
        end

        context "when there are multiple pages of labels" do
          let(:label_hash_3) { {name: "low-risk", url: "github.com", color: "343434"} }
          let(:label_hash_4) { {name: "high-risk", url: "github.com", color: "565656"} }
          let(:label_hash_5) { {name: "low-risk", url: "github.com", color: "343434"} }
          let(:label_hash_6) { {name: "high-risk", url: "github.com", color: "565656"} }
          let(:labels_hash_2) { [label_hash_3,label_hash_4] }
          let(:labels_hash_3) { [label_hash_5,label_hash_6] }
          let(:label3) { Label.new(name: "low-risk", color: "343434") }
          let(:label4) { Label.new(name: "high-risk", color: '565656') }
          let(:label5) { Label.new(name: "low-risk", color: "343434") }
          let(:label6) { Label.new(name: "high-risk", color: '565656') }

          before do
            allow(GitHub).to receive(:labels).with(config.github_repo, page: 2).and_return(labels_hash_2)
            allow(GitHub).to receive(:labels).with(config.github_repo, page: 3).and_return(labels_hash_3)
            allow(GitHub).to receive(:labels).with(config.github_repo, page: 4).and_return([])
          end

          it "should go through multiple pages of repos" do
            expect(Label.send(:all_from_repo)).to eq([label1, label2, label3, label4, label5, label6])
          end
        end
      end
    end
  end
end
