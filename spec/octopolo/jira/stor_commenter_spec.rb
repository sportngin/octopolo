require "spec_helper"
require_relative "../../../lib/octopolo/jira/story_commenter"

module Octopolo
  module Jira
    describe StoryCommenter do
      let(:comments) { stub }
      let(:issue) { stub(:comments => comments) }
      context ".new" do
        it "finds the issue via the jira api" do
          Jiralicious.should_receive(:configure)
          Jiralicious::Issue.should_receive(:find).with(:id).and_return(issue)
          StoryCommenter.new(:id, 'text')
        end
      end

      context "#perform" do
        let(:comment) { "test comment" }
        before do
          Jiralicious::Issue.stub(:find).with(:id).and_return(issue)
        end

        it "creates a new note for the story" do
          comments.should_receive(:add).with(comment)
          StoryCommenter.new(:id, comment).perform
        end
      end
    end
  end
end
