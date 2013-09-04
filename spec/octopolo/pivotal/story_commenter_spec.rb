require "spec_helper"
require "automation/pivotal/story_commenter"

module Automation
  module Pivotal
    describe StoryCommenter do
      let(:client) { stub }
      before do
        Pivotal::Client.stub(:new) { client }
      end

      context ".new" do
        it "finds the story via the pivotal api" do
          client.should_receive(:find_story).with(:id)
          StoryCommenter.new(:id, 'text')
        end
      end

      context "#perform" do
        let(:notes) { stub }
        let(:story) { stub(notes: notes) }
        let(:comment) { "test comment" }

        it "creates a new note for the story" do
          client.stub(:find_story) { story }
          note = stub
          notes.should_receive(:new).with(owner: story, text: comment) { note }
          note.should_receive(:create)
          StoryCommenter.new(story, comment).perform
        end
      end
    end
  end
end
