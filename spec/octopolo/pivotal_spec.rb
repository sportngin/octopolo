require "spec_helper"
require "octopolo/pivotal"

module Octopolo
  module Pivotal
    describe Client do

      let(:user_config) { stub(:user_config, pivotal_token: "token") }

      before do
        Client.any_instance.stub(user_config: user_config)
      end

      context ".new" do
        it "forces the PivotalTracker gem to use SSL" do
          ::PivotalTracker::Client.should_receive(:use_ssl=).with(true)
          Pivotal::Client.new
        end
      end

      context ".fetch_token(email, password)" do
        let(:email) { "example@example.com" }
        let(:password) { "sekret" }
        let(:token) { "dead-beef" }

        it "passes down to the PivotalTracker gem" do
          ::PivotalTracker::Client.should_receive(:token).with(email, password) { token }
          expect(Client.fetch_token email, password).to eq(token)
        end

        it "raises BadCredentials if given invalid credentials" do
          ::PivotalTracker::Client.should_receive(:token).and_raise(RestClient::Unauthorized)
          expect { Client.fetch_token email, password }.to raise_error(BadCredentials)
        end
      end

      context "#find_story(story_id)" do
        let(:project) { PivotalTracker::Project.new }
        let(:story) { PivotalTracker::Story.new }

        it "gets all of the PT projects" do
          project.stub_chain(:stories, :find).with(:id) { story }
          PivotalTracker::Project.should_receive(:all) { [project] }
          subject.find_story(:id)
        end

        it "finds the story that matches the id" do
          PivotalTracker::Project.stub(:all) { [project] }
          project.stub_chain(:stories, :find).with(:id) { story }
          expect(subject.find_story(:id)).to eq(story)
        end

        it "raises StoryNoteFound if no story is found" do
          PivotalTracker::Project.stub(:all) { [] }
          project.stub_chain(:stories, :find).with(:id) { nil }
          expect { subject.find_story(:id) }.to raise_error(StoryNotFound)
        end
      end
    end
  end
end
