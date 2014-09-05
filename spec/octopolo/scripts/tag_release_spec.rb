require "spec_helper"
require "octopolo/scripts/tag_release"

module Octopolo
  module Scripts
    describe TagRelease do
      let(:config) { stub(:config, deploy_branch: "something", semantic_versioning: false) }
      let(:cli) { stub(:cli) }
      let(:git) { stub(:git) }
      let(:prefix) { "foo" }
      let(:suffix) { "bar" }
      let(:options) { Hash.new }
      subject { TagRelease.new }

      before do
        TagRelease.any_instance.stub({
          :cli => cli,
          :config => config,
          :git => git
        })
        TagRelease.any_instance.stub(:update_changelog)
        options[:force] = false
        options[:major] = false
        options[:minor] = false
        options[:patch] = false
      end

      describe "#new" do
        it "accepts a flag to set the tag prefix" do
          options[:prefix] = prefix
          expect(TagRelease.new(options).prefix).to eq(prefix)
        end

        it "accepts a flag to set the tag suffix" do
          options[:suffix] = suffix
          expect(TagRelease.new(options).suffix).to eq(suffix)
        end

        it "accepts a switch to force creating the new tag even if not on deploy branch" do
          options[:force] = true
          expect(TagRelease.new(options).force?).to be_true
        end

        it "accepts a switch to increment major version" do
          options[:major] = true
          expect(TagRelease.new(options).major?).to be_true
        end

        it "accepts a switch to increment minor version" do
          options[:minor] = true
          expect(TagRelease.new(options).minor?).to be_true
        end

        it "accepts a switch to increment patch version" do
          options[:patch] = true
          expect(TagRelease.new(options).patch?).to be_true
        end

        it "defaults to no suffix and not to force" do
          expect(subject.suffix).to be_nil
          expect(subject.force?).to be_falsey
        end
      end

      describe "#execute" do
        it "tags the release if on the release branch" do
          subject.stub(:should_create_branch?) { true }
          subject.should_receive(:tag_release)
          subject.execute
        end

        it "does nothing if not on the release branch" do
          subject.stub(:should_create_branch?) { false }
          subject.should_not_receive(:tag_release)
          expect { subject.execute }.to raise_error(Octopolo::WrongBranch)
        end
      end

      describe "#should_create_branch?" do
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

      describe "#tag_release" do
        it "tells Git to make the tag" do
          subject.stub(:tag_name) { "some-tag" }
          git.should_receive(:new_tag).with(subject.tag_name)
          subject.tag_release
        end
      end

      describe "#tag_name" do
        context "with timestamp tag" do
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

        context "with semantic versioning tag of 0.0.2" do
          before do
            subject.config.stub(:semantic_versioning) { true }
            subject.git.stub(:semver_tags) { ['0.0.1', '0.0.2'] }
          end

          context "incrementing patch" do
            it "bumps the version to 0.0.3" do
              subject.patch = true
              expect(subject.tag_name).to eq('0.0.3')
            end
          end

          context "incrementing minor" do
            it "bumps the version to 0.1.0" do
              subject.minor = true
              expect(subject.tag_name).to eq('0.1.0')
            end
          end

          context "incrementing major" do
            it "bumps the version to 1.0.0" do
              subject.major = true
              expect(subject.tag_name).to eq('1.0.0')
            end
          end

          context "with a prefix of v" do
            before do
              subject.major = true
              subject.git.stub(:semver_tags) { %w[v0.0.1 v0.0.2] }
            end

            it "sets the prefix to v" do
              subject.tag_name
              expect(subject.prefix).to eq('v')
            end

            it "returns the tag name with the prefix" do
              subject.instance_variable_set(:@tag_name, nil)
              expect(subject.tag_name).to eq('v1.0.0')
            end
          end
        end
      end # describe "#tag_name"

      describe "#scrub_tag" do
        let(:tag) { "v0.0.2" }

        it "sets the prefix" do
          subject.scrub_tag tag
          expect(subject.prefix).to eq("v")
        end

        it "does not overwrite the prefix" do
          subject.prefix = "prefix"
          subject.scrub_tag tag
          expect(subject.prefix).to eq("prefix")
        end

        it "returns the scrubbed tag" do
          expect(subject.scrub_tag tag).to eq("0.0.2")
        end
      end

      describe "#ask_user_version" do
        let(:semver_choice_question) { "Which version section do you want to increment?" }

        it "sets @major when user response with 'Major'" do
          expect(subject.cli).to receive(:ask).with(semver_choice_question, TagRelease::SEMVER_CHOICES)
                                              .and_return('Major')
          subject.ask_user_version
          expect(subject.major).to be_true
        end

        it "sets @minor when user response with 'minor'" do
          expect(subject.cli).to receive(:ask).with(semver_choice_question, TagRelease::SEMVER_CHOICES)
                                              .and_return('Minor')
          subject.ask_user_version
          expect(subject.minor).to be_true
        end

        it "sets @patch when user response with 'patch'" do
          expect(subject.cli).to receive(:ask).with(semver_choice_question, TagRelease::SEMVER_CHOICES)
                                              .and_return('Patch')
          subject.ask_user_version
          expect(subject.patch).to be_true
        end
      end

    end
  end
end

