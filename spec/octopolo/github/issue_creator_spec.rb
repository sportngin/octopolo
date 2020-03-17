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
          expect(IssueCreator).to receive(:new).with(repo_name, options) { creator }
          expect(creator).to receive(:perform)
          expect(IssueCreator.perform(repo_name, options)).to eq(creator)
        end
      end

      context ".new repo_name, options" do
        it "remembers the repo name and options" do
          creator = IssueCreator.new repo_name, options
          expect(creator.repo_name).to eq(repo_name)
          expect(creator.options).to eq(options)
        end
      end

      context "#perform" do
        let(:data) { double(:mash, number: 123) }

        before do
          allow(creator).to receive_messages({
            title: title,
            body: body,
          })
        end

        it "generates the issue with the given details and retains the information" do
          expect(GitHub).to receive(:create_issue).with(repo_name, title, body, labels: []) { data }
          expect(creator.perform).to eq(data)
          expect(creator.number).to eq(data.number)
          expect(creator.data).to eq(data)
        end

        it "raises CannotCreate if any exception occurs" do
          expect(GitHub).to receive(:create_issue).and_raise(Octokit::UnprocessableEntity)
          expect { creator.perform }.to raise_error(IssueCreator::CannotCreate)
        end
      end

      context "#number" do
        let(:number) { 123 }

        it "returns the stored issue number" do
          creator.number = number
          expect(creator.number).to eq(number)
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
          expect(creator.data).to eq(details)
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
            expect(creator.title).to eq(title)
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
          allow(creator).to receive_messages({
            jira_ids: jira_ids,
            jira_url: jira_url,
          })
        end
        it "includes the necessary keys to render the template" do
          expect(creator.body_locals[:jira_ids]).to eq(creator.jira_ids)
          expect(creator.body_locals[:jira_url]).to eq(creator.jira_url)
        end
      end

      context "#edit_body" do
        let(:path) { double(:path) }
        let(:body) { double(:string) }
        let(:tempfile) { double(:tempfile) }
        let(:edited_body) { double(:edited_body) }

        before do
          allow(Tempfile).to receive(:new) { tempfile }
          allow(tempfile).to receive_messages(path: path, write: nil, read: edited_body, unlink: nil, close: nil, open: nil)
          allow(creator).to receive(:system)
        end

        context "without the $EDITOR env var set" do
          before do
            stub_const('ENV', {'EDITOR' => nil})
          end

          it "returns the un-edited output" do
            expect(creator.edit_body(body)).to eq(body)
          end
        end

        context "with the $EDITOR env set" do

          before do
            stub_const('ENV', {'EDITOR' => 'vim'})
          end

          it "creates a tempfile, write default contents, and close it" do
            expect(Tempfile).to receive(:new).with(['octopolo_issue', '.md']) { tempfile }
            expect(tempfile).to receive(:write).with(body)
            expect(tempfile).to receive(:close)
            creator.edit_body body
          end

          it "edits the tempfile with the $EDITOR" do
            expect(tempfile).to receive(:path) { path }
            expect(creator).to receive(:system).with("vim #{path}")
            creator.edit_body body
          end

          it "reopens the file, gets the contents, and deletes the temp file" do
            expect(tempfile).to receive(:open)
            expect(tempfile).to receive(:read) { edited_body }
            expect(tempfile).to receive(:unlink)
            creator.edit_body body
          end

          it "returns the user edited output" do
            expect(creator.edit_body(body)).to eq(edited_body)
          end
        end
      end

      context "#body" do
        let(:locals) { double(:hash) }
        let(:output) { double(:string) }

        before do
          allow(creator).to receive_messages({
            body_locals: locals,
          })
        end

        it "renders the body template with the body locals" do
          expect(Renderer).to receive(:render).with(Renderer::ISSUE_BODY, locals) { output }
          expect(creator.body).to eq(output)
        end

        context "when the editor option is set" do
          let(:edited_output) { double(:output) }

          before do
            allow(creator).to receive_messages({
              body_locals: locals,
              options: { editor: true }
            })
          end

          it "calls the edit_body method" do
            expect(Renderer).to receive(:render).with(Renderer::ISSUE_BODY, locals) { output }
            expect(creator).to receive(:edit_body).with(output) { edited_output }
            expect(creator.body).to eq(edited_output)
          end
        end
      end
    end
  end
end
