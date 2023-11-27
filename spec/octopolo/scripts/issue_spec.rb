require "spec_helper"
require_relative "../../../lib/octopolo/scripts/issue"
require_relative "../../../lib/octopolo/github/issue"

module Octopolo
  module Scripts
    describe Issue do
      let(:config) do
        double(:config, {
          deploy_branch: "production",
          github_repo: "tstmedia/foo",
          use_jira: true
        })
      end
      let(:cli) { double(:cli) }
      let(:git) { double(:Git) }
      let(:issue_url) { "http://github.com/tstmedia/octopolo/issues/0" }
      let(:issue) { double(:issue) }

      subject { Issue.new }

      before do
        Issue.any_instance.stub({
          :cli => cli,
          :config => config,
          :git => git
        })

        Octopolo::Question.any_instance.stub({
          :cli => cli
        })
      end

      context "#new" do
        it "accepts options" do
          expect(Issue.new(:foo => 'bar').options).to eq(:foo => 'bar')
        end
      end

      context "#execute" do
        it "if connected to GitHub, asks some questions, creates the issue, and opens it" do
          GitHub.should_receive(:connect).and_yield
          expect(subject).to receive(:ask_questionaire)
          expect(subject).to receive(:create_issue)
          expect(subject).to receive(:update_jira)
          expect(subject).to receive(:update_labels)
          expect(subject).to receive(:open_in_browser)

          subject.execute
        end

        it "if not connected to GitHub, does nothing" do
          GitHub.should_receive(:connect) # and not yield, no github credentials
          expect { subject.execute }.to_not raise_error
        end
      end

      context "#ask_questionaire" do
        it "asks appropriate questions to create a issue" do
          expect(subject).to receive(:announce)
          expect(subject).to receive(:ask_title)
          expect(subject).to receive(:ask_jira_ids)
          expect(subject).to receive(:ask_labels)

          subject.send(:ask_questionaire)
        end
      end

      context "#announce" do
        it "displays information about the issue to be created" do
          cli.should_receive(:say).with("Preparing an issue for #{config.github_repo}.")
          subject.send(:announce)
        end
      end

      context "#ask_title" do
        let(:title) { "title" }

        it "asks for and captures a title for the issue" do
          cli.should_receive(:prompt).with("Title:") { title }
          subject.send(:ask_title)
          expect(subject.title).to eq(title)
        end
      end

      context "#ask_labels" do
        let(:label1) {Octopolo::GitHub::Label.new(name: "low-risk", color: '151515')}
        let(:label2) {Octopolo::GitHub::Label.new(name: "high-risk", color: '151515')}
        let(:choices) {["low-risk","high-risk"]}

        it "asks for and capture a label" do
          allow(Octopolo::GitHub::Label).to receive(:all) {[label1,label2]}
          expect(cli).to receive(:ask).with("Label:", choices.concat(["None"]))
          subject.send(:ask_labels)
        end

        it "asks for a label" do
          allow(Octopolo::GitHub::Label).to receive(:all) {[label1,label2]}
          allow(Octopolo::GitHub::Label).to receive(:get_names) {choices}
          allow(cli).to receive(:ask) {"low-risk"}
          expect(subject.send(:ask_labels)).to eq([label1])
        end
      end

      context "#create_issue" do
        let(:attributes) { double(:hash) }

        before do
          subject.stub(:issue_attributes) { attributes }
        end

        it "creates and stores the issue" do
          GitHub::Issue.should_receive(:create).with(config.github_repo, attributes) { issue }
          subject.send(:create_issue)
          expect(subject.issue).to eq(issue)
        end
      end

      context "#issue_attributes" do
        before do
          subject.title = "title"
        end

        it "combines the anssers with a handful of deault values" do
          subject.send(:issue_attributes).should eq({
            title: subject.title,
            jira_ids: subject.jira_ids,
            editor: nil
          })
        end
      end

      context "#label_choices" do
        let(:label1) { Octopolo::GitHub::Label.new(name: "low-risk", color: '151515') }
        let(:label2) { Octopolo::GitHub::Label.new(name: "high-risk", color: '151515') }
        let(:github_labels) { [label1, label2] }

        it "returns the labels plus 'None'" do
          allow(Octopolo::GitHub::Label).to receive(:all) { github_labels }
          expect(subject.send(:label_choices)).to eq github_labels
        end
      end

      context "#update_labels" do
        before do
          subject.labels = "high-risk"
          subject.issue = double()
        end
        it "calls update_labels with proper arguments" do
          expect(subject.issue).to receive(:add_labels).with('high-risk')
          subject.send(:update_labels)
        end

        context "doesn't know yet label" do
          before do
            subject.labels = nil
          end
          it "doesn't call update_labels when label is don't know yet" do
            expect(subject.issue).to_not receive(:add_labels)
            subject.send(:update_labels)
          end
        end

      end

      context "#open_in_browser" do
        before do
          subject.issue = issue
          issue.stub(:url) { issue_url }
        end

        it "copies the issue's URL to the clipboard and opens it in the browser" do
          cli.should_receive(:copy_to_clipboard) { issue.url}
          cli.should_receive(:open) { issue.url }
          subject.send(:open_in_browser)
        end
      end
    end
  end
end
