require "spec_helper"
require_relative "../../../lib/octopolo/github"

module Octopolo
  module GitHub
    describe PullRequestCreator do
      let(:creator) { PullRequestCreator.new repo_name, options }
      let(:repo_name) { "foo/bar" }
      let(:options) { {} }
      let(:destination_branch) { "master" }
      let(:source_branch) { "cool-feature" }
      let(:title) { "title" }
      let(:body) { "body" }
      let(:pivotal_ids) { %w(123 456) }
      let(:jira_ids) { %w(123 456) }
      let(:jira_url) { "https://example-jira.com" }

      context ".perform repo_name, options" do
        let(:creator) { stub }

        it "instantiates a creator and perfoms it" do
          PullRequestCreator.should_receive(:new).with(repo_name, options) { creator }
          creator.should_receive(:perform)
          PullRequestCreator.perform(repo_name, options).should == creator
        end
      end

      context ".new repo_name, options" do
        it "remembers the repo name and options" do
          creator = PullRequestCreator.new repo_name, options
          creator.repo_name.should == repo_name
          creator.options.should == options
        end
      end

      context "#perform" do
        let(:data) { stub(:mash, number: 123) }

        before do
          creator.stub({
            destination_branch: destination_branch,
            source_branch: source_branch,
            title: title,
            body: body,
          })
        end

        it "generates the pull request with the given details and retains the information" do
          GitHub.should_receive(:create_pull_request).with(
            repo_name, destination_branch, source_branch, title, body, {draft: true}
          ) { data }
          creator.perform.should == data
          creator.number.should == data.number
          creator.data.should == data
        end

        it "raises CannotCreate if any exception occurs" do
          GitHub.should_receive(:create_pull_request).and_raise(Octokit::UnprocessableEntity)
          expect { creator.perform }.to raise_error(PullRequestCreator::CannotCreate)
        end
      end

      context "#number" do
        let(:number) { 123 }

        it "returns the stored pull request number" do
          creator.number = number
          creator.number.should == number
        end

        it "raises an exception if no pull request has been created yet" do
          creator.number = nil
          expect { creator.number }.to raise_error(PullRequestCreator::NotYetCreated)
        end
      end

      context "#data" do
        let(:details) { stub(:data) }

        it "returns the stored pull request details" do
          creator.data = details
          creator.data.should == details
        end

        it "raises an exception if no information has been captured yet" do
          creator.data = nil
          expect { creator.data }.to raise_error(PullRequestCreator::NotYetCreated)
        end
      end

      context "#destination_branch" do
        it "fetches from the options" do
          creator.options[:destination_branch] = destination_branch
          creator.destination_branch.should == destination_branch
        end

        it "raises an exception if it's missing" do
          creator.options[:destination_branch] = nil
          expect { creator.destination_branch }.to raise_error(PullRequestCreator::MissingAttribute)
        end
      end

      context "#source_branch" do
        it "fetches from the options" do
          creator.options[:source_branch] = source_branch
          creator.source_branch.should == source_branch
        end

        it "raises an exception if it's missing" do
          creator.options[:source_branch] = nil
          expect { creator.source_branch }.to raise_error(PullRequestCreator::MissingAttribute)
        end
      end

      context "#title" do
        context "having the option set" do
          before { creator.options[:title] = title }

          it "fetches from the options" do
            creator.title.should == title
          end
        end

        it "raises an exception if it's missing" do
          creator.options[:title] = nil
          expect { creator.title }.to raise_error(PullRequestCreator::MissingAttribute)
        end
      end

      context "#pivotal_ids" do
        it "fetches from the options" do
          creator.options[:pivotal_ids] = pivotal_ids
          creator.pivotal_ids.should == pivotal_ids
        end

        it "defaults to an empty array if it's missing" do
          creator.options[:pivotal_ids] = nil
          creator.pivotal_ids.should == []
        end
      end

      context "#body_locals" do
        let(:urls) { %w(link1 link2) }

        before do
          creator.stub({
            pivotal_ids: pivotal_ids,
            jira_ids: jira_ids,
            jira_url: jira_url,
          })
        end
        it "includes the necessary keys to render the template" do
          creator.body_locals[:pivotal_ids].should == creator.pivotal_ids
          creator.body_locals[:jira_ids].should == creator.jira_ids
          creator.body_locals[:jira_url].should == creator.jira_url
        end
      end

      context "#edit_body" do
        let(:path) { stub(:path) }
        let(:body) { stub(:string) }
        let(:tempfile) { stub(:tempfile) }
        let(:edited_body) { stub(:edited_body) }

        before do
          Tempfile.stub(:new) { tempfile }
          tempfile.stub(path: path, write: nil, read: edited_body, unlink: nil, close: nil, open: nil)
          creator.stub(:system)
        end

        context "without the $EDITOR env var set" do
          before do
            stub_const('ENV', {'EDITOR' => nil})
          end

          it "returns the un-edited output" do
            creator.edit_body(body).should == body
          end
        end

        context "with the $EDITOR env set" do

          before do
            stub_const('ENV', {'EDITOR' => 'vim'})
          end

          it "creates a tempfile, write default contents, and close it" do
            Tempfile.should_receive(:new).with(['octopolo_pull_request', '.md']) { tempfile }
            tempfile.should_receive(:write).with(body)
            tempfile.should_receive(:close)
            creator.edit_body body
          end

          it "edits the tempfile with the $EDITOR" do
            tempfile.should_receive(:path) { path }
            creator.should_receive(:system).with("vim #{path}")
            creator.edit_body body
          end

          it "reopens the file, gets the contents, and deletes the temp file" do
            tempfile.should_receive(:open)
            tempfile.should_receive(:read) { edited_body }
            tempfile.should_receive(:unlink)
            creator.edit_body body
          end

          it "returns the user edited output" do
            creator.edit_body(body).should == edited_body
          end
        end
      end

      context "#body" do
        let(:locals) { stub(:hash) }
        let(:output) { stub(:string) }

        before do
          creator.stub({
            body_locals: locals,
          })
        end

        it "renders the body template with the body locals" do
          Renderer.should_receive(:render).with(Renderer::PULL_REQUEST_BODY, locals) { output }
          creator.body.should == output
        end

        context "when the editor option is set" do
          let(:edited_output) { stub(:output) }

          before do
            creator.stub({
              body_locals: locals,
              options: { editor: true }
            })
          end

          it "calls the edit_body method" do
            Renderer.should_receive(:render).with(Renderer::PULL_REQUEST_BODY, locals) { output }
            creator.should_receive(:edit_body).with(output) { edited_output }
            creator.body.should == edited_output
          end
        end
      end
    end
  end
end
