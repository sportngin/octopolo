require "spec_helper"
require_relative "../../../lib/octopolo/zapier/pull_request_poster"

module Octopolo
  module Zapier
    describe PullRequestPoster do
      let(:prefix) { "pull" }
      let(:endpoint) { 123 }
      let(:file1) { "file1.json" }
      let(:file2) { "file2.json" }

      subject { PullRequestPoster.new(prefix, [endpoint]) }

      context ".new(prefix, zap_ids)" do
        it "remembers the prefix and Zapier endpoint IDs given to it" do
          expect(subject.prefix).to eq prefix
          expect(subject.endpoints).to eq [endpoint]
        end
      end

      context "#perform" do
        it "posts each pull request JSON entries to Zapier" do
          subject.stub(json_files: [file1, file2] )
          subject.should_receive(:post).with(file1)
          subject.should_receive(:delete).with(file1)
          subject.should_receive(:post).with(file2)
          subject.should_receive(:delete).with(file2)

          subject.perform
        end
      end

      context "#json_files" do
        it "finds the properly named JSON files in the current directory" do
          Dir.should_receive(:glob).with(".#{prefix}-*.json") { [file1, file2] }
          expect(subject.json_files).to eq [file1, file2]
        end
      end

      context "#post file" do
        let(:endpoints) { [123, 456] }
        let(:curl123) { "curl -H 'Content-Type: application/json' -X POST -d @#{file1} #{Zapier.endpoint(123)}" }
        let(:curl456) { "curl -H 'Content-Type: application/json' -X POST -d @#{file1} #{Zapier.endpoint(456)}" }

        before do
          subject.stub(endpoints: endpoints)
        end

        it "posts the given file to each endpoint" do
          Octopolo::CLI.should_receive(:perform_quietly).with(curl123)
          Octopolo::CLI.should_receive(:perform_quietly).with(curl456)

          subject.post file1
        end
      end

      context "#delete file" do
        before do
          subject.stub(json_files: [file1])
        end

        it "deletes the given file" do
          Octopolo::CLI.should_receive(:perform).with("rm #{file1}")
          subject.delete file1
        end

        it "does not delete the file if not one of the matching json files" do
          Octopolo::CLI.should_receive(:perform).never
          subject.delete file2
        end
      end
    end
  end
end
