require "spec_helper"
require "octopolo/scripts/compare_release"

module Octopolo
  module Scripts
    describe CompareRelease do
      let(:config) { stub(:config, github_repo: "tstmedia/ngin") }
      let(:cli) { stub(:cli) }
      let(:git) { stub(:git, recent_release_tags: tags) }
      let(:tags) { %w(tag1 tag2) }

      subject { CompareRelease.new '' }

      before do
        subject.config = config
        subject.cli = cli
        subject.git = git
      end

      context "#parse" do
        it "properly handles no arguments" do
          subject.parse([])
          subject.start.should be_nil
          subject.stop.should be_nil
        end

        it "accepts the first argument as the start tag" do
          subject.parse(["foo"])
          subject.start.should == "foo"
          subject.stop.should be_nil
        end

        it "accepts the second argument as the end tag" do
          subject.parse(["foo", "bar"])
          subject.start.should == "foo"
          subject.stop.should == "bar"
        end
      end

      context "#execute" do
        it "prompts for starting and ending tag, then opens the comparei page" do
          subject.should_receive(:ask_starting_tag)
          subject.should_receive(:ask_stopping_tag)
          subject.should_receive(:open_compare_page)

          subject.execute
        end
      end

      context "#ask_starting_tag" do
        it "prompts to select from the list of release tags" do
          cli.should_receive(:ask).with("Start with which tag?", tags) { tags.first }
          subject.ask_starting_tag
          subject.start.should == tags.first
        end

        it "does nothing if alread has a starting tag" do
          subject.start = "foo"
          cli.should_not_receive(:ask)
          subject.ask_starting_tag
        end
      end

      context "#ask_stopping_tag" do
        before do
          subject.start = "foo"
        end

        it "prompts to select form the list of release tags" do
          cli.should_receive(:ask).with("Compare from #{subject.start} to which tag?", tags) { tags.last }
          subject.ask_stopping_tag
          subject.stop.should == tags.last
        end

        it "does nothing if already has an ending tag" do
          subject.stop = "bar"
          cli.should_not_receive(:ask)
          subject.ask_stopping_tag
        end
      end

      context "#open_compare_page" do
        let(:url) { "http://example.com/" }

        it "copies the compare URL to the clipboard and opens it" do
          subject.stub(:compare_url) { url }
          cli.should_receive(:copy_to_clipboard).with(url)
          cli.should_receive(:open).with(url)

          subject.open_compare_page
        end
      end

      context "#compare_url" do
        let(:start) { "foo" }
        let(:stop) { "bar" }

        before do
          subject.start = start
          subject.stop = stop
        end

        it "builds the URL from the starting and stopping tags" do
          subject.compare_url.should == "https://github.com/#{config.github_repo}/compare/#{start}...#{stop}?w=1"
        end
      end
    end
  end
end

