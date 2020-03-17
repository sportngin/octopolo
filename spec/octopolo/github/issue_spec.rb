require "spec_helper"
require_relative "../../../lib/octopolo/github/issue"
require_relative "../../../lib/octopolo/github/issue_creator"

module Octopolo
  module GitHub
    describe Issue do
      let(:repo_name) { "account/repo" }
      let(:issue_number) { 7 }
      let(:issue_hash) { double }
      let(:comments) { double }
      let(:octo) { double }

      context ".new" do
        it "remembers the issue identifiers" do
          i = Issue.new repo_name, issue_number
          expect(i.repo_name).to eq(repo_name)
          expect(i.number).to eq(issue_number)
        end

        it "optionally accepts the github data" do
          i = Issue.new repo_name, issue_number, octo
          expect(i.data).to eq(octo)
        end

        it "fails if not given a repo name" do
          expect { Issue.new nil, issue_number }.to raise_error(Issue::MissingParameter)
        end

        it "fails if not given a issue number" do
          expect { Issue.new repo_name, nil }.to raise_error(Issue::MissingParameter)
        end
      end

      context "#data" do
        let(:issue) { Issue.new repo_name, issue_number }

        it "fetches the details from GitHub" do
          expect(GitHub).to receive(:issue).with(issue.repo_name, issue.number) { octo }
          expect(issue.data).to eq(octo)
        end

        it "catches the information" do
          expect(GitHub).to receive(:issue).once { octo }
          issue.data
          issue.data
        end

        it "fails if given invalid information" do
          expect(GitHub).to receive(:issue).and_raise(Octokit::NotFound)
          expect { issue.data }.to raise_error(Issue::NotFound)
        end
      end

      context "fetching its attributes from Octokit" do
        let(:issue) { Issue.new repo_name, issue_number }

        before do
          allow(issue).to receive_messages(data: octo)
        end

        context "#title" do
          let(:octo) { double(title: "the title") }

          it "retrieves from the github data" do
            expect(issue.title).to eq(octo.title)
          end
        end

        context "#comments" do
          it "fetches through octokit" do
            expect(GitHub).to receive(:issue_comments).with(issue.repo_name, issue.number) { comments }
            expect(issue.comments).to eq(comments)
          end

          it "caches the result" do
            expect(GitHub).to receive(:issue_comments).once { comments }
            issue.comments
            issue.comments
          end
        end

        context "#commenter_names" do
          let(:comment1) { double(user: double(login: "pbyrne")) }
          let(:comment2) { double(user: double(login: "anfleene")) }

          before do
            allow(issue).to receive_messages(comments: [comment1, comment2])
          end

          it "returns only unique values" do
            # make it same commenter
            allow(comment2.user).to receive_messages(login: comment1.user.login)
            names = issue.commenter_names
            expect(names.size).to eq(1)
          end
        end

        context "#without_octopolo_users" do
          let(:users) { ["anfleene", "tst-octopolo"] }

          it "excludes the github octopolo users" do
            expect(issue.exclude_octopolo_user(users)).not_to include("tst-octopolo")
            expect(issue.exclude_octopolo_user(users)).to include("anfleene")
          end
        end

        context "#url" do
          let(:octo) { double(html_url: "http://example.com") }

          it "retrieves from the github data" do
            expect(issue.url).to eq(octo.html_url)
          end
        end

        context "#external_urls" do
          # nicked from https://github.com/tstmedia/ngin/issue/1151
          let(:body) do
            <<-END
              http://thedesk.tstmedia.com/admin.php?pg=request&reqid=44690 - verified
              http://thedesk.tstmedia.com/admin.php?pg=request&reqid=44693 - verified

                development_ftp_server: ftp.tstmedia.com
                development_username: startribuneftptest@ftp.tstmedia.com
                development_password: JUm1kU7STYt0
              http://www.ngin.com.stage.ngin-staging.com/api/volleyball/stats/summaries?id=68382&gender=girls&tst_test=1&date=8/24/2012
            END
          end

          before do
            allow(issue).to receive_messages(body: body)
          end

          it "parses from the body" do
            urls = issue.external_urls
            expect(urls.size).to eq(3)
            expect(urls).to include "http://thedesk.tstmedia.com/admin.php?pg=request&reqid=44690"
            expect(urls).to include "http://thedesk.tstmedia.com/admin.php?pg=request&reqid=44693"
            expect(urls).to include "http://www.ngin.com.stage.ngin-staging.com/api/volleyball/stats/summaries?id=68382&gender=girls&tst_test=1&date=8/24/2012"
          end
        end

        context "#body" do
          let(:octo) { double(body: "asdf") }

          it "retrieves from the github data" do
            expect(issue.body).to eq(octo.body)
          end

          it "returns an empty string if the GitHub data has no body" do
            allow(octo).to receive_messages(body: nil)
            expect(issue.body).to eq("")
          end
        end
      end

      context "#human_app_name" do
        let(:repo_name) { "account_name/repo_name" }
        let(:issue) { Issue.new repo_name, issue_number }

        it "infers from the repo_name" do
          issue.repo_name = "account/foo"
          expect(issue.human_app_name).to eq("Foo")
          issue.repo_name = "account/foo_bar"
          expect(issue.human_app_name).to eq("Foo Bar")
        end
      end

      context "#write_comment(message)" do
        let(:issue) { Issue.new repo_name, issue_number }
        let(:message) { "Test message" }
        let(:error) { Octokit::UnprocessableEntity.new }

        it "creates the message through octokit" do
          expect(GitHub).to receive(:add_comment).with(issue.repo_name, issue.number, ":octocat: #{message}")

          issue.write_comment message
        end

        it "raises CommentFailed if an exception occurs" do
          expect(GitHub).to receive(:add_comment).and_raise(error)

          expect { issue.write_comment message }.to raise_error(Issue::CommentFailed, "Unable to write the comment: '#{error.message}'")
        end
      end

      context ".create repo_name, options" do
        let(:options) { double(:hash) }
        let(:number) { double(:integer) }
        let(:data) { double(:data)}
        let(:creator) { double(:issue_creator, number: number, data: data)}
        let(:issue) { double(:issue) }

        it "passes on to IssueCreator and returns a new Issue" do
          expect(IssueCreator).to receive(:perform).with(repo_name, options) { creator }
          expect(Issue).to receive(:new).with(repo_name, number, data) { issue }
          expect(Issue.create(repo_name, options)).to eq(issue)
        end
      end

      context "labeling" do
        let(:label1) { Label.new(name: "low-risk", color: "343434") }
        let(:label2) { Label.new(name: "high-risk", color: '565656') }
        let(:issue) { Issue.new repo_name, issue_number }

        context "#add_labels" do
          it "sends the correct arguments to add_labels_to_issue for multiple labels" do
            allow(Label).to receive(:build_label_array) {[label1,label2]}
            expect(GitHub).to receive(:add_labels_to_issue).with(repo_name, issue_number, ["low-risk","high-risk"])
            issue.add_labels([label1, label2])
          end

          it "sends the correct arguments to add_labels_to_issue for a single label" do
            allow(Label).to receive(:build_label_array) {[label1]}
            expect(GitHub).to receive(:add_labels_to_issue).with(repo_name, issue_number, ["low-risk"])
            issue.add_labels(label1)
          end
        end

        context "#remove_from_issue" do

          it "sends the correct arguments to remove_label" do
            allow(Label).to receive(:build_label_array) {[label1]}
            expect(GitHub).to receive(:remove_label).with(repo_name, issue_number, "low-risk")
            issue.remove_labels(label1)
          end

          it "calls remove_label only once" do
            allow(Label).to receive(:build_label_array) {[label1]}
            expect(GitHub).to receive(:remove_label).once
            issue.remove_labels(label1)
          end

          it "calls remove_label twice" do
            allow(Label).to receive(:build_label_array) {[label1, label2]}
            expect(GitHub).to receive(:remove_label).twice
            issue.remove_labels([label1,label2])
          end
        end
      end
    end
  end
end
