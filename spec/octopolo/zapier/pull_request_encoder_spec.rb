require "spec_helper"
require "automation/zapier/pull_request_encoder"

module Automation
  module Zapier
    describe PullRequestEncoder do
      let(:pull_request) { stub(:pull_request) }
      let(:prefix) { "pull" }

      subject { PullRequestEncoder.new pull_request, prefix }

      context ".new pull_request" do
        it "captures the given pull_request object and encoded prefix" do
          expect(subject.pull_request).to eq pull_request
          expect(subject.prefix).to eq prefix
        end
      end

      context "#perform" do
        it "writes the JSON file" do
          subject.should_receive(:write_json)
          subject.perform
        end
      end

      context "#write_json" do
        let(:json_file) { stub }
        let(:encoded_json) { stub }

        before do
          subject.stub({
            json_file: json_file,
            encoded_json: encoded_json,
          })
        end

        it "writes the encoded json to file" do
          json_file.should_receive(:puts).with(encoded_json)
          json_file.should_receive(:close)
          subject.write_json
        end
      end

      context "#json_file" do
        let(:pull_request) { stub(number: 123) }

        it "opens a file based on the pull request's number" do
          File.should_receive(:open).with(".#{prefix}-#{pull_request.number}.json", "w")
          subject.json_file
        end
      end

      context "#encoded_json" do
        let(:attrs) do
          {
            author_names: ["bob", "sally"],
            commenter_names: ["jane", "billy"],
            title: "title",
            url: "http://example.com/",
            issue_urls: %w(http://helpspot.example.com/123 http://helpspot.example.com/234),
            human_app_name: "Foo",
          }
        end
        let(:pull_request) { stub(attrs) }

        before do
          subject.stub(trello_color: "blue")
        end

        it "includes the app name" do
          expect(JSON.parse(subject.encoded_json).fetch("appname")).to eq pull_request.human_app_name
        end

        it "includes the authors" do
          pull_request.author_names.each do |author_name|
            expect(JSON.parse(subject.encoded_json).fetch("authors")).to include author_name
          end
        end

        it "includes the commenters" do
          pull_request.commenter_names.each do |commenter_name|
            expect(JSON.parse(subject.encoded_json).fetch("commenters")).to include commenter_name
          end
        end

        it "includes the pull request's title" do
          expect(JSON.parse(subject.encoded_json).fetch("title")).to eq pull_request.title
        end

        it "includes the pull request's URL" do
          expect(JSON.parse(subject.encoded_json).fetch("url")).to eq pull_request.url
        end

        it "includes any issue URLs" do
          pull_request.issue_urls.each do |issue_url|
            expect(JSON.parse(subject.encoded_json).fetch("issue_urls")).to include issue_url
          end
        end

        it "includes the trello color for the pull request" do
          expect(JSON.parse(subject.encoded_json).fetch("color")).to eq subject.trello_color
        end

        it "includes today's date as the accepted_on date" do
          expect(Date.parse(JSON.parse(subject.encoded_json).fetch("accepted_on"))).to eq Date.today
        end
      end

      context "#trello_color" do
        before do
          pull_request.stub({
            bug?: false,
            release?: false,
          })
        end

        it "is blue by default" do
          expect(subject.trello_color).to eq "blue"
        end

        it "is red for bugs" do
          pull_request.stub(bug?: true)
          expect(subject.trello_color).to eq "red"
        end

        it "is green for release pull requests" do
          pull_request.stub(release?: true)
          expect(subject.trello_color).to eq "green"
        end
      end
    end
  end
end
