require "spec_helper"
require_relative "../../../lib/octopolo/scripts/pull_request"

module Octopolo
  module Scripts
    describe PullRequest do
      let(:config) do
        stub(:config, {
          deploy_branch: "production",
          github_repo: "tstmedia/foo"
        })
      end
      let(:cli) { stub(:cli) }
      let(:git) { stub(:Git, current_branch: "bug-123-something", reserved_branch?: false) }
      let(:pull_request_url) { "http://github.com/tstmedia/octopolo/pull/0" }
      let(:pull_request) { stub(:pull_request) }

      subject { PullRequest.new '' }

      before do
        subject.cli = cli
        subject.config = config
        subject.git = git
      end

      context "#parse" do
        it "defaults the destination branch to the deploy branch" do
          subject.parse([])
          expect(subject.destination_branch).to eq(config.deploy_branch)
        end

        it "accepts an alternate destination branch" do
          subject.parse(%w(--destination foo))
          expect(subject.destination_branch).to eq("foo")
        end
      end

      context "#execute" do
        it "if connected to GitHub, asks some questions, creates the pull request, and opens it" do
          GitHub.should_receive(:connect).and_yield
          subject.should_receive(:ask_questionaire)
          subject.should_receive(:create_pull_request)
          subject.should_receive(:update_pivotal)
          subject.should_receive(:open_pull_request)

          subject.execute
        end

        it "if not connected to GitHub, does nothing" do
          GitHub.should_receive(:connect) # and not yield, no github credentials
          expect { subject.execute }.to_not raise_error
        end
      end

      context "#ask_questionaire" do
        it "asks appropriate questions to create a pull request" do
          subject.should_receive(:announce)
          subject.should_receive(:ask_title)
          subject.should_receive(:ask_description)
          subject.should_receive(:ask_pivotal_ids)
          subject.should_receive(:ask_release)

          subject.send(:ask_questionaire)
        end

        context "when checking for staging branch" do
          before do
            subject.stub(:announce)
            subject.stub(:ask_title)
            subject.stub(:ask_description)
            subject.stub(:ask_pivotal_ids)
            subject.stub(:ask_release)
          end
          it "exits when branch name is reserved" do
            subject.git.stub(:reserved_branch?).and_return true

            subject.should_receive(:alert_reserved_and_exit)

            subject.send(:ask_questionaire)
          end

          it "should not ask if the branch is not staging" do
            subject.git.stub(:reserved_branch?).and_return false

            subject.should_not_receive(:alert_reserved_and_exit)

            subject.send(:ask_questionaire)
          end
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

      context "#ask_description" do
        let(:description) { "description" }

        it "asks for and captures a description for the pull request" do
          cli.should_receive(:prompt).with("Description (1 or 2 sentences):") { description }
          subject.send(:ask_description)
          expect(subject.description).to eq(description)
        end
      end

      context "#ask_pivotal_ids" do
        let(:ids_with_whitespace) { "123 456" }
        let(:ids_with_commas) { "234, 567" }

        it "asks for and captures IDs for related pivotal tasks" do
          cli.should_receive(:prompt).with("Pivotal Tracker story ID(s):") { ids_with_whitespace }
          subject.send(:ask_pivotal_ids)
          expect(subject.pivotal_ids).to eq(%w(123 456))
        end

        it "asks for and captures IDs with commas" do
          cli.should_receive(:prompt).with("Pivotal Tracker story ID(s):") { ids_with_commas }
          subject.send(:ask_pivotal_ids)
          expect(subject.pivotal_ids).to eq(%w(234 567))
        end

        it "sets to an empty array if not provided an ansswer" do
          cli.should_receive(:prompt).with("Pivotal Tracker story ID(s):") { "" }
          subject.send(:ask_pivotal_ids)
          expect(subject.pivotal_ids).to eq([])
        end
      end

      context "#ask_release" do
        let(:release) { stub(:boolean) }

        it "asks for and captures whether this is a release pull request" do
          cli.should_receive(:ask_boolean).with("Is this a Release pull request?") { release }
          subject.send(:ask_release)
          expect(subject.release).to eq(release)
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
          subject.description = "description"
          subject.destination_branch = "some-branch",
          subject.release = true
          subject.pivotal_ids = %w(123)
        end

        it "combines the anssers with a handful of deault values" do
          subject.send(:pull_request_attributes).should == {
            title: subject.title,
            description: subject.description,
            release: subject.release,
            destination_branch: subject.destination_branch,
            source_branch: git.current_branch,
            pivotal_ids: subject.pivotal_ids,
          }
        end
      end

      context "#update_pivotal" do
        before do
          subject.pivotal_ids = %w(123 234)
          subject.pull_request = stub(url: "test")
        end
        let(:story_commenter) { stub(perform: true) }

        it "creates a story commenter for each pivotal_id" do
          Pivotal::StoryCommenter.should_receive(:new).with("123", "test") { story_commenter }
          Pivotal::StoryCommenter.should_receive(:new).with("234", "test") { story_commenter }
          subject.send(:update_pivotal)
        end

      end

      context "#open_pull_request" do
        before do
          subject.pull_request = pull_request
          pull_request.stub(:url) { pull_request_url }
        end

        it "copies the pull request's URL to the clipboard and opens it in the browser" do
          cli.should_receive(:copy_to_clipboard) { pull_request.url}
          cli.should_receive(:open) { pull_request.url }
          subject.send(:open_pull_request)
        end
      end
    end
  end
end
