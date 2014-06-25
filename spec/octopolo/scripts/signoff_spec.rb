require "spec_helper"
require "octopolo/scripts/signoff"

module Octopolo
  module Scripts
    describe Signoff do
      # stub any attributes in the config that you need
      let(:config) { stub(:config, github_repo: "sportngin/foo") }
      let(:cli) { stub(:cli) }
      let(:pull_request_id) { 123 }
      let(:pull_request) { stub(:pull_request, url: "http://example.com") }

      subject { Signoff.new }
      before do
        cli.stub(:prompt)
        Signoff.any_instance.stub(:cli => cli, :config => config)
      end

      context "#new" do
        it "sets the pull_request_id if passed in from args" do
          expect(Signoff.new(pull_request_id.to_s).pull_request_id).to eq pull_request_id.to_s
        end

        it "prompts if no pull_request_id is given" do
          cli.should_receive(:prompt)
             .with("Pull Request ID: ")
             .and_return("42")
          expect(Signoff.new.pull_request_id).to eq "42"
        end
      end

      context "#execute" do
        it "asks which type of signoff is being performed and posts a prefab comment" do
          subject.should_receive(:preamble)
          subject.should_receive(:ask_signoff_type)
          subject.should_receive(:write_comment)
          subject.should_receive(:open_pull_request)
          subject.execute
        end
      end

      context "#preamble" do
        before do
          pull_request.stub({
            title: "Test PR",
            number: pull_request_id,
            url: "http://example.com/",
          })
          subject.send(:pull_request=, pull_request)
        end

        it "displays information about the given pull request" do
          cli.should_receive(:say).with(%Q(Please review "#{pull_request.title}":))
          cli.should_receive(:say).with(pull_request.url)
          cli.should_receive(:spacer_line)

          subject.send(:preamble)
        end
      end

      context "#ask_signoff_type" do
        let(:selected_type) { Signoff::TYPES.first }

        it "asks user to choose which signoff type to perform and remebers it" do
          cli.should_receive(:ask).with("Which type of signoff are you performing?", Signoff::TYPES) { selected_type }
          subject.send(:ask_signoff_type)
          expect(subject.signoff_type).to eq selected_type
        end
      end

      context "#write_comment" do
        let(:body) { "asdf" }
        before do
          subject.send(:pull_request=, pull_request)
          subject.stub(:comment_body) { body }
        end

        it "submits a comment that the pull request is signed off" do
          pull_request.should_receive(:write_comment).with(body)

          subject.send(:write_comment)
        end
      end

      context "#comment_body" do
        let(:selected_type) { Signoff::TYPES.first }

        before do
          subject.signoff_type = selected_type
        end

        it "injects the signoff type" do
          expect(subject.send(:comment_body)).to eq "Signing off on **#{selected_type}**."
        end
      end

      context "#open_pull_request" do
        before do
          subject.send(:pull_request=, pull_request)
        end

        it "opens the pull request in the browser" do
          cli.should_receive(:open).with(pull_request.url)
          subject.send(:open_pull_request)
        end
      end

      context "#pull_request" do
        before do
          subject.pull_request_id = pull_request_id
        end

        it "fetches the pull request matching the ID" do
          GitHub::PullRequest.should_receive(:new).with(config.github_repo, pull_request_id) { pull_request }
          expect(subject.send(:pull_request)).to eq pull_request
        end

        it "caches that object" do
          GitHub::PullRequest.should_receive(:new).once.and_return(pull_request)
          subject.send(:pull_request)
          subject.send(:pull_request)
        end

        it "remembers the pull request given to it" do
          GitHub::PullRequest.should_not_receive(:new)
          subject.send(:pull_request=, pull_request)
          expect(subject.send(:pull_request)).to eq pull_request
        end

        it "fails if the pull_request_id is not an int" do
          subject.pull_request_id = 'foo'
          expect { subject.send(:pull_request) }.to raise_error ArgumentError
        end
      end
    end
  end
end

# vim: set ft=ruby : #
