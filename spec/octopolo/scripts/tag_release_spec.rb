require "spec_helper"
require "octopolo/scripts/tag_release"

module Octopolo
  module Scripts
    describe TagRelease do
      let(:config) { double(:config, deploy_branch: "something", semantic_versioning: false) }
      let(:cli) { double(:cli) }
      let(:git) { double(:git) }
      let(:prefix) { "foo" }
      let(:suffix) { "bar" }
      let(:options) { Hash.new }
      subject { TagRelease.new }

      before do
        allow_any_instance_of(TagRelease).to receive_messages({
          :cli => cli,
          :config => config,
          :git => git
        })
        allow_any_instance_of(TagRelease).to receive(:update_changelog)
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
          expect(TagRelease.new(options).force?).to be_truthy
        end

        it "accepts a switch to increment major version" do
          options[:major] = true
          expect(TagRelease.new(options).major?).to be_truthy
        end

        it "accepts a switch to increment minor version" do
          options[:minor] = true
          expect(TagRelease.new(options).minor?).to be_truthy
        end

        it "accepts a switch to increment patch version" do
          options[:patch] = true
          expect(TagRelease.new(options).patch?).to be_truthy
        end

        it "defaults to no suffix and not to force" do
          expect(subject.suffix).to be_nil
          expect(subject.force?).to be_falsey
        end
      end

      describe "#execute" do
        it "tags the release if on the release branch" do
          allow(subject).to receive(:should_create_branch?) { true }
          expect(subject).to receive(:tag_release)
          subject.execute
        end

        it "does nothing if not on the release branch" do
          allow(subject).to receive(:should_create_branch?) { false }
          expect(subject).not_to receive(:tag_release)
          expect { subject.execute }.to raise_error(Octopolo::WrongBranch)
        end
      end

      describe "#should_create_branch?" do
        before do
          subject.force = false
        end

        it "is true if on the deploy branch" do
          allow(git).to receive(:current_branch) { config.deploy_branch }
          expect(subject.should_create_branch?).to be_truthy
        end

        context "if not on the deploy branch" do
          before do
            allow(git).to receive(:current_branch) { "something-else" }
          end

          it "is true if set to force creation" do
            subject.force = true
            expect(subject.should_create_branch?).to be_truthy
          end

          it "is false otherwise" do
            subject.force = false
            expect(subject.should_create_branch?).to be_falsey
          end
        end
      end

      describe "#tag_release" do
        it "tells Git to make the tag" do
          allow(subject).to receive(:tag_name) { "some-tag" }
          expect(git).to receive(:new_tag).with(subject.tag_name)
          subject.tag_release
        end
      end

      describe "#tag_name" do
        context "with timestamp tag" do
          let(:sample_time) { Time.new }
          let(:formatted_timestamp) { sample_time.strftime(TagRelease::TIMESTAMP_FORMAT) }

          before do
            allow(Time).to receive(:now) { sample_time }
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
            allow(subject.config).to receive(:semantic_versioning) { true }
            allow(subject.git).to receive(:semver_tags) { ['0.0.1', '0.0.2'] }
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
              allow(subject.git).to receive(:semver_tags) { %w[v0.0.1 v0.0.2] }
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

      describe "#ask_user_version" do
        let(:semver_choice_question) { "Which version section do you want to increment?" }

        it "sets @major when user response with 'Major'" do
          expect(subject.cli).to receive(:ask).with(semver_choice_question, TagRelease::SEMVER_CHOICES)
                                              .and_return('Major')
          subject.ask_user_version
          expect(subject.major).to be_truthy
        end

        it "sets @minor when user response with 'minor'" do
          expect(subject.cli).to receive(:ask).with(semver_choice_question, TagRelease::SEMVER_CHOICES)
                                              .and_return('Minor')
          subject.ask_user_version
          expect(subject.minor).to be_truthy
        end

        it "sets @patch when user response with 'patch'" do
          expect(subject.cli).to receive(:ask).with(semver_choice_question, TagRelease::SEMVER_CHOICES)
                                              .and_return('Patch')
          subject.ask_user_version
          expect(subject.patch).to be_truthy
        end
      end

      describe "#set_prefix" do
        let(:tag) { "v0.0.2" }
        let(:git) { double(:semver_tags => [tag]) }

        it "sets the prefix" do
          subject.set_prefix
          expect(subject.prefix).to eq("v")
        end

        it "does not overwrite the prefix" do
          subject.prefix = "prefix"
          subject.set_prefix
          expect(subject.prefix).to eq("prefix")
        end
      end

    end
  end
end

