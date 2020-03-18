require "spec_helper"
require "octopolo/scripts/compare_release"

module Octopolo
  module Scripts
    describe CompareRelease do
      let(:config) { double(:config, github_repo: "tstmedia/ngin") }
      let(:cli) { double(:cli) }
      let(:git) { double(:git, recent_release_tags: tags) }
      let(:tags) { %w(tag1 tag2) }

      subject { CompareRelease.new }

      before do
        subject.config = config
        subject.cli = cli
        subject.git = git
      end

      context "#intialize" do
        it "properly handles no arguments" do
          expect(subject.start).to be_nil
          expect(subject.stop).to be_nil
        end

        context "with a starting tag only" do
          subject { CompareRelease.new "foo" }

          it "sets the start tag only" do
            expect(subject.start).to eq("foo")
            expect(subject.stop).to be_nil
          end
        end

        context "with a start and end tag" do
          subject { CompareRelease.new "foo", "bar" }

          it "sets the start and end tags" do
            expect(subject.start).to eq("foo")
            expect(subject.stop).to eq("bar")
          end
        end
      end

      context "#execute" do
        it "prompts for starting and ending tag, then opens the comparei page" do
          expect(subject).to receive(:ask_starting_tag)
          expect(subject).to receive(:ask_stopping_tag)
          expect(subject).to receive(:open_compare_page)

          subject.execute
        end
      end

      context "#ask_starting_tag" do
        it "prompts to select from the list of release tags" do
          expect(cli).to receive(:ask).with("Start with which tag?", tags) { tags.first }
          subject.ask_starting_tag
          expect(subject.start).to eq(tags.first)
        end

        it "does nothing if alread has a starting tag" do
          subject.start = "foo"
          expect(cli).not_to receive(:ask)
          subject.ask_starting_tag
        end
      end

      context "#ask_stopping_tag" do
        before do
          subject.start = "foo"
        end

        it "prompts to select form the list of release tags" do
          expect(cli).to receive(:ask).with("Compare from #{subject.start} to which tag?", tags) { tags.last }
          subject.ask_stopping_tag
          expect(subject.stop).to eq(tags.last)
        end

        it "does nothing if already has an ending tag" do
          subject.stop = "bar"
          expect(cli).not_to receive(:ask)
          subject.ask_stopping_tag
        end
      end

      context "#open_compare_page" do
        let(:url) { "http://example.com/" }

        it "copies the compare URL to the clipboard and opens it" do
          allow(subject).to receive(:compare_url) { url }
          expect(cli).to receive(:copy_to_clipboard).with(url)
          expect(cli).to receive(:open).with(url)

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
          expect(subject.compare_url).to eq("https://github.com/#{config.github_repo}/compare/#{start}...#{stop}?w=1")
        end
      end
    end
  end
end

