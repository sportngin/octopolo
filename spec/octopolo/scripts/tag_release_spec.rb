require "spec_helper"
require "octopolo/scripts/tag_release"

module Octopolo
  module Scripts
    describe TagRelease do
      let(:config) { stub(:config, deploy_branch: "something") }
      let(:cli) { stub(:cli) }
      let(:git) { stub(:git) }
      let(:suffix) { "foo" }
      subject { TagRelease.new '' }

      before do
        subject.cli = cli
        subject.config = config
        subject.git = git
        subject.stub(:update_changelog)
      end

      context "#parse" do
        it "accepts the given parameter as the tag suffix" do
          subject.parse([suffix])
          expect(subject.suffix).to eq(suffix)
        end

        it "accepts a flag to force creating the new tag even if not on deploy branch" do
          subject.parse(["--force"])
          expect(subject.force?).to be_true
        end

        it "defaults to no suffix and not to force" do
          subject.parse([])
          expect(subject.suffix).to be_nil
          expect(subject.force?).to be_false
        end
      end

      context "#execute" do
        it "tags the release if on the release branch" do
          subject.stub(:should_create_branch?) { true }
          subject.should_receive(:tag_release)
          subject.execute
        end

        it "does nothing if not on the release branch" do
          subject.stub(:should_create_branch?) { false }
          subject.should_not_receive(:tag_release)
          expect { subject.execute }.to raise_error(Clamp::UsageError)
        end
      end

      context "#should_create_branch?" do
        before do
          subject.force = false
        end

        it "is true if on the deploy branch" do
          git.stub(:current_branch) { config.deploy_branch }
          expect(subject.should_create_branch?).to be_true
        end

        context "if not on the deploy branch" do
          before do
            git.stub(:current_branch) { "something-else" }
          end

          it "is true if set to force creation" do
            subject.force = true
            expect(subject.should_create_branch?).to be_true
          end

          it "is false otherwise" do
            subject.force = false
            expect(subject.should_create_branch?).to be_false
          end
        end
      end

      context "#tag_release" do
        it "tells Git to make the tag" do
          subject.stub(:tag_name) { "somet-tag" }
          git.should_receive(:new_tag).with(subject.tag_name)
          subject.tag_release
        end
      end

      context "#tag_name" do
        let(:sample_time) { Time.new }
        let(:formatted_timestamp) { sample_time.strftime(TagRelease::TIMESTAMP_FORMAT) }

        before do
          Time.stub(:now) { sample_time }
        end

        it "is based on the timestamp" do
          subject.suffix = nil
          expect(subject.tag_name).to eq(formatted_timestamp)
        end

        it "applies the suffix if has one" do
          subject.suffix = suffix
          expect(subject.tag_name).to eq("#{formatted_timestamp}_#{suffix}")
        end
      end
    end
  end
end

