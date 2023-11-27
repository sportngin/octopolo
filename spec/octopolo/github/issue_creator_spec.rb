require "spec_helper"
require_relative "../../../lib/octopolo/github/issue_creator"

module Octopolo
  module GitHub
    describe IssueCreator do
      let(:creator) { IssueCreator.new repo_name, options }
      let(:repo_name) { "foo/bar" }
      let(:options) { {} }
      let(:title) { "title" }
      let(:body) { "body" }
      let(:jira_ids) { %w(123 456) }
      let(:jira_url) { "https://example-jira.com" }

      context ".perform repo_name, options" do
        let(:creator) { double }

        it "instantiates a creator and perfoms it" do
          IssueCreator.should_receive(:new).with(repo_name, options) { creator }
          creator.should_receive(:perform)
          IssueCreator.perform(repo_name, options).should eq(creator)
        end
      end

      context ".new repo_name, options" do
        it "remembers the repo name and options" do
          creator = IssueCreator.new repo_name, options
          creator.repo_name.should eq(repo_name)
          creator.options.should eq(options)
        end
      end

      context "#perform" do
        let(:data) { double(:mash, number: 123) }

        before do
          creator.stub({
            title: title,
            body: body,
          })
        end

        it "generates the issue with the given details and retains the information" do
          GitHub.should_receive(:create_issue).with(repo_name, title, body, labels: []) { data }
          creator.perform.should eq(data)
          creator.number.should eq(data.number)
          creator.data.should eq(data)
        end

        it "raises CannotCreate if any exception occurs" do
          GitHub.should_receive(:create_issue).and_raise(Octokit::UnprocessableEntity)
          expect { creator.perform }.to raise_error(IssueCreator::CannotCreate)
        end
      end

      context "#number" do
        let(:number) { 123 }

        it "returns the stored issue number" do
          creator.number = number
          creator.number.should eq(number)
        end

        it "raises an exception if no issue has been created yet" do
          creator.number = nil
          expect { creator.number }.to raise_error(IssueCreator::NotYetCreated)
        end
      end

      context "#data" do
        let(:details) { double(:data) }

        it "returns the stored issue details" do
          creator.data = details
          creator.data.should eq(details)
        end

        it "raises an exception if no information has been captured yet" do
          creator.data = nil
          expect { creator.data }.to raise_error(IssueCreator::NotYetCreated)
        end
      end

      context "#title" do
        context "having the option set" do
          before { creator.options[:title] = title }

          it "fetches from the options" do
            creator.title.should eq(title)
          end
        end

        it "raises an exception if it's missing" do
          creator.options[:title] = nil
          expect { creator.title }.to raise_error(IssueCreator::MissingAttribute)
        end
      end

      context "#body_locals" do
        let(:urls) { %w(link1 link2) }

        before do
          creator.stub({
            jira_ids: jira_ids,
            jira_url: jira_url,
          })
        end
        it "includes the necessary keys to render the template" do
          creator.body_locals[:jira_ids].should eq(creator.jira_ids)
          creator.body_locals[:jira_url].should eq(creator.jira_url)
        end
      end

      context "#edit_body" do
        let(:path) { double(:path) }
        let(:body) { double(:string) }
        let(:tempfile) { double(:tempfile) }
        let(:edited_body) { double(:edited_body) }

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
            creator.edit_body(body).should eq(body)
          end
        end

        context "with the $EDITOR env set" do

          before do
            stub_const('ENV', {'EDITOR' => 'vim'})
          end

          it "creates a tempfile, write default contents, and close it" do
            Tempfile.should_receive(:new).with(['octopolo_issue', '.md']) { tempfile }
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
            creator.edit_body(body).should eq(edited_body)
          end
        end
      end

      context "#body" do
        let(:locals) { double(:hash) }
        let(:output) { double(:string) }

        before do
          creator.stub({
            body_locals: locals,
          })
        end

        it "renders the body template with the body locals" do
          Renderer.should_receive(:render).with(Renderer::ISSUE_BODY, locals) { output }
          creator.body.should eq(output)
        end

        context "when the editor option is set" do
          let(:edited_output) { double(:output) }

          before do
            creator.stub({
              body_locals: locals,
              options: { editor: true }
            })
          end

          it "calls the edit_body method" do
            Renderer.should_receive(:render).with(Renderer::ISSUE_BODY, locals) { output }
            creator.should_receive(:edit_body).with(output) { edited_output }
            creator.body.should eq(edited_output)
          end
        end
      end
    end
  end
end
