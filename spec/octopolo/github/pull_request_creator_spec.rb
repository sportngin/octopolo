require "spec_helper"
require "automation/github/pull_request_creator"

module Automation
  module GitHub
    describe PullRequestCreator do
      let(:creator) { PullRequestCreator.new repo_name, options }
      let(:repo_name) { "foo/bar" }
      let(:options) { {} }
      let(:destination_branch) { "master" }
      let(:source_branch) { "cool-feature" }
      let(:title) { "title" }
      let(:body) { "body" }
      let(:description) { "description" }
      let(:pivotal_ids) { %w(123 456) }

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
        let(:pull_request_data) { stub(:mash, number: 123) }

        before do
          creator.stub({
            destination_branch: destination_branch,
            source_branch: source_branch,
            title: title,
            body: body,
          })
        end

        it "generates the pull request with the given details and retains the information" do
          GitHub.should_receive(:create_pull_request).with(repo_name, destination_branch, source_branch, title, body) { pull_request_data }
          creator.perform.should == pull_request_data
          creator.number.should == pull_request_data.number
          creator.pull_request_data.should == pull_request_data
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

      context "#pull_request_data" do
        let(:details) { stub(:pull_request_data) }

        it "returns the stored pull request details" do
          creator.pull_request_data = details
          creator.pull_request_data.should == details
        end

        it "raises an exception if no information has been captured yet" do
          creator.pull_request_data = nil
          expect { creator.pull_request_data }.to raise_error(PullRequestCreator::NotYetCreated)
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

      context "#release?" do
        it "is true if the option is set to true" do
          creator.options[:release] = true
          creator.should be_release
        end

        it "is false if the option is set to false" do
          creator.options[:release] = false
          creator.should_not be_release
        end

        it "is nil if the option isn't set" do
          creator.options[:release] = nil
          creator.should_not be_release
        end
      end

      context "#title" do
        context "having the option set" do
          before { creator.options[:title] = title }

          it "prefixes 'Release: ' for a release pull request" do
            creator.stub(:release?) { true }
            creator.title.should == "Release: #{title}"
          end

          it "uses the raw value otherwise" do
            creator.stub(:release?) { false }
            creator.title.should == title
          end
        end

        it "raises an exception if it's missing" do
          creator.options[:title] = nil
          expect { creator.title }.to raise_error(PullRequestCreator::MissingAttribute)
        end
      end

      context "#description" do
        it "fetches from the options" do
          creator.options[:description] = description
          creator.description.should == description
        end

        it "raises an exception if it's missing" do
          creator.options[:description] = nil
          expect { creator.description }.to raise_error(PullRequestCreator::MissingAttribute)
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
        let(:description) { "description" }
        let(:urls) { %w(link1 link2) }

        before do
          creator.stub({
            description: description,
            pivotal_ids: pivotal_ids,
          })
        end
        it "includes the necessary keys to render the template" do
          creator.body_locals[:description].should == creator.description
          creator.body_locals[:pivotal_ids].should == creator.pivotal_ids
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
      end
    end
  end
end
