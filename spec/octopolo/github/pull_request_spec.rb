require "spec_helper"
require_relative "../../../lib/octopolo/github/pull_request"

module Octopolo
  module GitHub
    describe PullRequest do
      let(:repo_name) { "account/repo" }
      let(:pr_number) { 7 }
      let(:prhash) { stub }
      let(:commits) { stub }
      let(:comments) { stub }
      let(:octo) { stub }

      context ".new" do
        it "remembers the pull request identifiers" do
          pr = PullRequest.new repo_name, pr_number
          pr.repo_name.should == repo_name
          pr.number.should == pr_number
        end

        it "optionally accepts the github data" do
          pr = PullRequest.new repo_name, pr_number, octo
          pr.pull_request_data.should == octo
        end

        it "fails if not given a repo name" do
          expect { PullRequest.new nil, pr_number }.to raise_error(PullRequest::MissingParameter)
        end

        it "fails if not given a pull request number" do
          expect { PullRequest.new repo_name, nil }.to raise_error(PullRequest::MissingParameter)
        end
      end

      context "#pull_request_data" do
        let(:pull) { PullRequest.new repo_name, pr_number }

        it "fetches the details from GitHub" do
          GitHub.should_receive(:pull_request).with(pull.repo_name, pull.number) { octo }
          pull.pull_request_data.should == octo
        end

        it "catches the information" do
          GitHub.should_receive(:pull_request).once { octo }
          pull.pull_request_data
          pull.pull_request_data
        end

        it "fails if given invalid information" do
          GitHub.should_receive(:pull_request).and_raise(Octokit::NotFound)
          expect { pull.pull_request_data }.to raise_error(PullRequest::NotFound)
        end
      end

      context "fetching its attributes from Octokit" do
        let(:pull) { PullRequest.new repo_name, pr_number }

        before do
          pull.stub(pull_request_data: octo)
        end

        context "#title" do
          let(:octo) { stub(title: "the title") }

          it "retrieves from the github data" do
            pull.title.should == octo.title
          end
        end

        context "#branch" do
          let(:octo) { stub(head: stub(ref: "asdf")) }

          it "retrieves from the github data" do
            pull.branch.should == octo.head.ref
          end
        end

        context "#commits" do
          it "fetches through octokit" do
            Commit.should_receive(:for_pull_request).with(pull) { commits }
            pull.commits.should == commits
          end

          it "caches the result" do
            Commit.should_receive(:for_pull_request).once { commits }
            pull.commits
            pull.commits
          end
        end

        context "#comments" do
          it "fetches through octokit" do
            GitHub.should_receive(:issue_comments).with(pull.repo_name, pull.number) { comments }
            pull.comments.should == comments
          end

          it "caches the result" do
            GitHub.should_receive(:issue_comments).once { comments }
            pull.comments
            pull.comments
          end
        end

        context "#author_names" do
          let(:commit1) { stub(author_name: "foo") }
          let(:commit2) { stub(author_name: "bar") }

          before do
            pull.stub(commits: [commit1, commit2])
          end

          it "returns the list of authors" do
            names = pull.author_names
            names.should_not be_empty
            names.count.should == 2
            names.first.should == "foo"
          end

          it "returns only unique values" do
            # make it same commenter
            commit2.stub(author_name: commit1.author_name)
            names = pull.author_names
            names.size.should == 1
          end
        end

        context "#commenter_names" do
          let(:comment1) { stub(user: stub(login: "pbyrne")) }
          let(:comment2) { stub(user: stub(login: "anfleene")) }

          before do
            pull.stub(comments: [comment1, comment2], author_names: [])
          end

          it "returns the names of the commit authors" do
            GitHub.stub(:user).with("pbyrne").and_return(Hashie::Mash.new(:name => "pbyrne"))
            GitHub.stub(:user).with("anfleene").and_return(Hashie::Mash.new(:name => "anfleene"))
            names = pull.commenter_names
            names.should_not be_empty
            names.size.should == 2
            names.first.should == "pbyrne"
          end

          it "returns only unique values" do
            # make it same commenter
            comment2.user.stub(login: comment1.user.login)
            names = pull.commenter_names
            names.size.should == 1
          end

          it "does not include authors in this list" do
            pull.stub(author_names: [comment1.user.login])
            names = pull.commenter_names
            names.size.should == 1
            names.should_not include comment1.user.login
          end
        end

        context "#without_octopolo_users" do
          let(:users) { ["anfleene", "tst-octopolo"] }

          it "excludes the github octopolo users" do
            pull.exlude_octopolo_user(users).should_not include("tst-octopolo")
            pull.exlude_octopolo_user(users).should include("anfleene")
          end
        end

        context "#url" do
          let(:octo) { stub(html_url: "http://example.com") }

          it "retrieves from the github data" do
            pull.url.should == octo.html_url
          end
        end

        context "#external_urls" do
          # nicked from https://github.com/tstmedia/ngin/pull/1151
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
            pull.stub(body: body)
          end

          it "parses from the body" do
            urls = pull.external_urls
            urls.size.should == 3
            urls.should include "http://thedesk.tstmedia.com/admin.php?pg=request&reqid=44690"
            urls.should include "http://thedesk.tstmedia.com/admin.php?pg=request&reqid=44693"
            urls.should include "http://www.ngin.com.stage.ngin-staging.com/api/volleyball/stats/summaries?id=68382&gender=girls&tst_test=1&date=8/24/2012"
          end
        end

        context "#issue_urls" do
          let(:helpspot) { "http://thedesk.tstmedia.com/admin.php?pg=request&reqid=44690" }
          let(:staging) { "http://www.ngin.com.stage.ngin-staging.com/api/volleyball/stats/summaries?id=68382&gender=girls&tst_test=1&date=8/24/2012" }
          let(:other) { "http://example.com/" }
          let(:urls) { [helpspot, staging, other] }

          before do
            pull.stub(external_urls: urls)
          end

          it "includes only certain URLs from the pull request" do
            urls = pull.issue_urls

            urls.should_not be_empty
            urls.size.should == 1
            urls.should include helpspot
            urls.should_not include staging
            urls.should_not include other
          end
        end

        context "#body" do
          let(:octo) { stub(body: "asdf") }

          it "retrieves from the github data" do
            pull.body.should == octo.body
          end

          it "returns an empty string if the GitHub data has no body" do
            octo.stub(body: nil)
            pull.body.should == ""
          end
        end

        context "#mergeable?" do
          it "retrieves from the github data" do
            octo.stub(mergeable: true)
            pull.should be_mergeable
            octo.stub(mergeable: false)
            pull.should_not be_mergeable
          end
        end

        context "#week" do
          it "retrieves from the github data" do
            octo.stub(closed_at: "2012-09-18T14:00:01Z")
            pull.week.should == Week.parse(octo.closed_at)
          end
        end
      end

      context "#bug?" do
        let(:pull) { PullRequest.new repo_name, pr_number }

        before do
          pull.stub({
            issue_urls: [],
            title: "something boring",
          })
        end

        it "is true if it has issue URLs" do
          pull.stub(issue_urls: ["http://example.com/123"])
          pull.should be_bug
        end

        it "is true if the title has 'bug' in it" do
          pull.stub(title: "Bug: something")
          pull.should be_bug
          pull.stub(title: "Fixes a bug in thing")
          pull.should be_bug
        end

        it "is true if the title has 'fix' in it" do
          pull.stub(title: "This PR fixes this thing")
          pull.should be_bug
          pull.stub(title: "Fix something that went wrong")
          pull.should be_bug
        end

        it "is false otherwise" do
          pull.should_not be_bug
        end
      end

      context "#human_app_name" do
        let(:repo_name) { "account_name/repo_name" }
        let(:pull) { PullRequest.new repo_name, pr_number }

        it "infers from the repo_name" do
          pull.repo_name = "account/foo"
          pull.human_app_name.should == "Foo"
          pull.repo_name = "account/foo_bar"
          pull.human_app_name.should == "Foo Bar"
        end
      end

      context ".closed repo_name" do
        let(:raw_pr) { stub(:octo_data, number: 123) }
        let(:pr_wrapper) { stub(:pull_request) }

        it "crawls the repo for pull requests and wraps them in PullRequests" do
          GitHub.should_receive(:pull_requests).with(repo_name, "closed") { [raw_pr] }
          PullRequest.should_receive(:new).with(repo_name, raw_pr.number, raw_pr) { pr_wrapper }

          result = PullRequest.closed(repo_name)
          result.should == [pr_wrapper]
        end
      end

      context "#write_comment(message)" do
        let(:pull) { PullRequest.new repo_name, pr_number }
        let(:message) { "Test message" }
        let(:error) { Octokit::UnprocessableEntity.new }

        it "creates the message through octokit" do
          GitHub.should_receive(:add_comment).with(pull.repo_name, pull.number, ":octocat: #{message}")

          pull.write_comment message
        end

        it "raises CommentFailed if an exception occurs" do
          GitHub.should_receive(:add_comment).and_raise(error)

          expect { pull.write_comment message }.to raise_error(PullRequest::CommentFailed, "Unable to write the comment: '#{error.message}'")
        end
      end

      context ".create repo_name, options" do
        let(:options) { stub(:hash) }
        let(:number) { stub(:integer) }
        let(:pull_request_data) { stub(:pull_request_data)}
        let(:creator) { stub(:pull_request_creator, number: number, pull_request_data: pull_request_data)}
        let(:pull_request) { stub(:pull_request) }

        it "passes on to PullRequestCreator and returns a new PullRequest" do
          PullRequestCreator.should_receive(:perform).with(repo_name, options) { creator }
          PullRequest.should_receive(:new).with(repo_name, number, pull_request_data) { pull_request }
          PullRequest.create(repo_name, options).should == pull_request
        end
      end

      context "#release?" do
        let(:pull) { PullRequest.new repo_name, pr_number }

        it "is true if the title begins with 'Release'" do
          pull.stub(:title) { "Release: Something something" }
          pull.should be_release
        end

        it "is false otherwise" do
          pull.stub(:title) { "Fixing some thing" }
          pull.should_not be_release
        end
      end
    end
  end
end
