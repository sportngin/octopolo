require "spec_helper"
require_relative "../../../lib/octopolo/github/issue"
require_relative "../../../lib/octopolo/github/issue_creator"

module Octopolo
  module GitHub
    describe Issue do
      let(:repo_name) { "account/repo" }
      let(:issue_number) { 7 }
      let(:issue_hash) { stub }
      let(:comments) { stub }
      let(:octo) { stub }

      context ".new" do
        it "remembers the issue identifiers" do
          i = Issue.new repo_name, issue_number
          i.repo_name.should == repo_name
          i.number.should == issue_number
        end

        it "optionally accepts the github data" do
          i = Issue.new repo_name, issue_number, octo
          i.issue_data.should == octo
        end

        it "fails if not given a repo name" do
          expect { Issue.new nil, issue_number }.to raise_error(Issue::MissingParameter)
        end

        it "fails if not given a issue number" do
          expect { Issue.new repo_name, nil }.to raise_error(Issue::MissingParameter)
        end
      end

      context "#issue_data" do
        let(:issue) { Issue.new repo_name, issue_number }

        it "fetches the details from GitHub" do
          GitHub.should_receive(:issue).with(issue.repo_name, issue.number) { octo }
          issue.issue_data.should == octo
        end

        it "catches the information" do
          GitHub.should_receive(:issue).once { octo }
          issue.issue_data
          issue.issue_data
        end

        it "fails if given invalid information" do
          GitHub.should_receive(:issue).and_raise(Octokit::NotFound)
          expect { issue.issue_data }.to raise_error(Issue::NotFound)
        end
      end

      context "fetching its attributes from Octokit" do
        let(:issue) { Issue.new repo_name, issue_number }

        before do
          issue.stub(issue_data: octo)
        end

        context "#title" do
          let(:octo) { stub(title: "the title") }

          it "retrieves from the github data" do
            issue.title.should == octo.title
          end
        end

        context "#comments" do
          it "fetches through octokit" do
            GitHub.should_receive(:issue_comments).with(issue.repo_name, issue.number) { comments }
            issue.comments.should == comments
          end

          it "caches the result" do
            GitHub.should_receive(:issue_comments).once { comments }
            issue.comments
            issue.comments
          end
        end

        context "#commenter_names" do
          let(:comment1) { stub(user: stub(login: "pbyrne")) }
          let(:comment2) { stub(user: stub(login: "anfleene")) }

          before do
            issue.stub(comments: [comment1, comment2])
          end

          it "returns only unique values" do
            # make it same commenter
            comment2.user.stub(login: comment1.user.login)
            names = issue.commenter_names
            names.size.should == 1
          end
        end

        context "#without_octopolo_users" do
          let(:users) { ["anfleene", "tst-octopolo"] }

          it "excludes the github octopolo users" do
            issue.exlude_octopolo_user(users).should_not include("tst-octopolo")
            issue.exlude_octopolo_user(users).should include("anfleene")
          end
        end

        context "#url" do
          let(:octo) { stub(html_url: "http://example.com") }

          it "retrieves from the github data" do
            issue.url.should == octo.html_url
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
            issue.stub(body: body)
          end

          it "parses from the body" do
            urls = issue.external_urls
            urls.size.should == 3
            urls.should include "http://thedesk.tstmedia.com/admin.php?pg=request&reqid=44690"
            urls.should include "http://thedesk.tstmedia.com/admin.php?pg=request&reqid=44693"
            urls.should include "http://www.ngin.com.stage.ngin-staging.com/api/volleyball/stats/summaries?id=68382&gender=girls&tst_test=1&date=8/24/2012"
          end
        end

        context "#body" do
          let(:octo) { stub(body: "asdf") }

          it "retrieves from the github data" do
            issue.body.should == octo.body
          end

          it "returns an empty string if the GitHub data has no body" do
            octo.stub(body: nil)
            issue.body.should == ""
          end
        end
      end

      context "#human_app_name" do
        let(:repo_name) { "account_name/repo_name" }
        let(:issue) { Issue.new repo_name, issue_number }

        it "infers from the repo_name" do
          issue.repo_name = "account/foo"
          issue.human_app_name.should == "Foo"
          issue.repo_name = "account/foo_bar"
          issue.human_app_name.should == "Foo Bar"
        end
      end

      context "#write_comment(message)" do
        let(:issue) { Issue.new repo_name, issue_number }
        let(:message) { "Test message" }
        let(:error) { Octokit::UnprocessableEntity.new }

        it "creates the message through octokit" do
          GitHub.should_receive(:add_comment).with(issue.repo_name, issue.number, ":octocat: #{message}")

          issue.write_comment message
        end

        it "raises CommentFailed if an exception occurs" do
          GitHub.should_receive(:add_comment).and_raise(error)

          expect { issue.write_comment message }.to raise_error(Issue::CommentFailed, "Unable to write the comment: '#{error.message}'")
        end
      end

      context ".create repo_name, options" do
        let(:options) { stub(:hash) }
        let(:number) { stub(:integer) }
        let(:issue_data) { stub(:issue_data)}
        let(:creator) { stub(:issue_creator, number: number, issue_data: issue_data)}
        let(:issue) { stub(:issue) }

        it "passes on to IssueCreator and returns a new Issue" do
          IssueCreator.should_receive(:perform).with(repo_name, options) { creator }
          Issue.should_receive(:new).with(repo_name, number, issue_data) { issue }
          Issue.create(repo_name, options).should == issue
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
