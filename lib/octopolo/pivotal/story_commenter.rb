require_relative '../pivotal'

module Octopolo
  module Pivotal
    class StoryCommenter
      attr_accessor :story
      attr_accessor :comment

      def initialize(story_id, comment)
        self.story = Pivotal::Client.new.find_story(story_id)
        self.comment = comment
      end

      def perform
        story.notes.new(:owner => story, :text => comment).create
      end
    end
  end
end
