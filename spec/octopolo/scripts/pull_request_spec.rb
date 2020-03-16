require "spec_helper"
require_relative "../../../lib/octopolo/scripts/pull_request"

module Octopolo
  module Scripts
    describe PullRequest do
      let(:config) do
        stub(:config, {
          deploy_branch: "production",
          github_repo: "tstmedia/foo",
          use_jira: true
        })
      end
      let(:cli) { stub(:cli) }
      let(:current_branch) { "bug-123-something" }
      let(:git) { stub(:Git, current_branch: current_branch, reserved_branch?: false) }
      let(:pull_request_url) { "http://github.com/tstmedia/octopolo/pull/0" }
      let(:pull_request) { stub(:pull_request) }

      subject { PullRequest.new }

      before do
        PullRequest.any_instance.stub({
          :cli => cli,
          :config => config,
          :git => git
        })

        Octopolo::Question.any_instance.stub({
          :cli => cli
        })
      end

      context "#new" do
        it "defaults the destination branch to the deploy branch" do
          expect(subject.destination_branch).to eq(config.deploy_branch)
        end

        it "accepts an alternate destination branch" do
          expect(PullRequest.new('foo').destination_branch).to eq("foo")
        end
      end

      context "#execute" do
        it "if connected to GitHub, asks some questions, creates the pull request, and opens it" do
          GitHub.should_receive(:connect).and_yield
          expect(subject).to receive(:ask_questionnaire)
          expect(subject).to receive(:create_pull_request)
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

      context "#ask_questionnaire" do
        it "asks appropriate questions to create a pull request" do
          expect(subject).to receive(:announce)
          expect(subject).to receive(:ask_title)
          expect(subject).to receive(:ask_jira_ids)
          expect(subject).to receive(:ask_labels)

          subject.send(:ask_questionnaire)
        end

        context "when checking for staging branch" do
          before do
            subject.stub(:announce)
            subject.stub(:ask_title)
            subject.stub(:ask_jira_ids)
            subject.stub(:ask_labels)
          end
          it "exits when branch name is reserved" do
            subject.git.stub(:reserved_branch?).and_return true

            subject.should_receive(:alert_reserved_and_exit)

            subject.send(:ask_questionnaire)
          end

          it "should not ask if the branch is not staging" do
            subject.git.stub(:reserved_branch?).and_return false

            subject.should_not_receive(:alert_reserved_and_exit)

            subject.send(:ask_questionnaire)
          end
        end
      end

      context "#expedite" do
        subject { PullRequest.new(nil, { expedite: true }) }

        context 'good format 1' do
          let(:current_branch) { 'abc-123_so_fast'}

          it 'likes the issue-123_blah branch format' do
            subject.send(:infer_questionnaire)
            expect(subject.jira_ids).to eq(['ABC-123'])
            expect(subject.title).to eq('ABC-123 So fast')
          end
        end

        context 'good format 2' do
          let(:current_branch) { 'abc_123_so_fast'}

          it 'likes the issue-123_blah branch format' do
            subject.send(:infer_questionnaire)
            expect(subject.jira_ids).to eq(['ABC-123'])
            expect(subject.title).to eq('ABC-123 So fast')
          end
        end

        context 'bad branch format' do
          let(:current_branch) { 'not_enough'}

          it 'does not like other branch format' do
            subject.git.stub(:reserved_branch?).and_return false
            cli.should_receive(:say)
            expect { subject.send(:infer_questionnaire) }.to raise_error(SystemExit)
          end
        end

        it 'does not process reserved' do
          subject.git.stub(:reserved_branch?).and_return true
          subject.should_receive(:alert_reserved_and_exit).and_call_original
          cli.should_receive(:say)
          expect { subject.send(:infer_questionnaire) }.to raise_error(SystemExit)
        end
      end

      context "#announce" do
        before do
          subject.destination_branch = "foo"
        end

        it "displays information about the pull request to be created" do
          cli.should_receive(:say).with("Preparing a pull request for #{config.github_repo}/#{git.current_branch} to #{config.github_repo}/#{subject.destination_branch}.")
          subject.send(:announce)
        end
      end

      context "#ask_title" do
        let(:title) { "title" }

        it "asks for and captures a title for the pull request" do
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

      context "#create_pull_request" do
        let(:attributes) { stub(:hash) }

        before do
          subject.stub(:pull_request_attributes) { attributes }
        end

        it "creates and stores the pull request" do
          GitHub::PullRequest.should_receive(:create).with(config.github_repo, attributes) { pull_request }
          subject.send(:create_pull_request)
          expect(subject.pull_request).to eq(pull_request)
        end
      end

      # GitHub::PullRequest.create config.github_repo, answers.merge({
      #   destination_branch: config.deploy_branch,
      #   source_branch: Git.current_branch,
      # })
      context "#pull_request_attributes" do
        before do
          subject.title = "title"
          subject.destination_branch = "some-branch",
        end

        it "combines the anssers with a handful of deault values" do
          subject.send(:pull_request_attributes).should == {
            title: subject.title,
            destination_branch: subject.destination_branch,
            source_branch: git.current_branch,
            jira_ids: subject.jira_ids,
            editor: nil
          }
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
          subject.labels = ["high-risk"]
          subject.pull_request = stub()
        end
        it "calls update_labels with proper arguments" do
          expect(subject.pull_request).to receive(:add_labels).with(['high-risk'])
          subject.send(:update_labels)
        end

        context "doesn't know yet label" do
          before do
            subject.labels = nil
          end
          it "doesn't call update_labels when label is don't know yet" do
            expect(subject.pull_request).to_not receive(:add_labels)
            subject.send(:update_labels)
          end
        end

      end

      context "#open_in_browser" do
        before do
          subject.pull_request = pull_request
          pull_request.stub(:url) { pull_request_url }
        end

        it "copies the pull request's URL to the clipboard and opens it in the browser" do
          cli.should_receive(:copy_to_clipboard) { pull_request.url}
          cli.should_receive(:open) { pull_request.url }
          subject.send(:open_in_browser)
        end
      end
    end
  end
end
