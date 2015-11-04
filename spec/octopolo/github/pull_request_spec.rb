require "spec_helper"
require_relative "../../../lib/octopolo/github"

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
          pr.data.should == octo
        end

        it "fails if not given a repo name" do
          expect { PullRequest.new nil, pr_number }.to raise_error(PullRequest::MissingParameter)
        end

        it "fails if not given a pull request number" do
          expect { PullRequest.new repo_name, nil }.to raise_error(PullRequest::MissingParameter)
        end
      end

      context "#data" do
        let(:pull) { PullRequest.new repo_name, pr_number }

        it "fetches the details from GitHub" do
          GitHub.should_receive(:pull_request).with(pull.repo_name, pull.number) { octo }
          pull.data.should == octo
        end

        it "catches the information" do
          GitHub.should_receive(:pull_request).once { octo }
          pull.data
          pull.data
        end

        it "fails if given invalid information" do
          GitHub.should_receive(:pull_request).and_raise(Octokit::NotFound)
          expect { pull.data }.to raise_error(PullRequest::NotFound)
        end
      end

      context "fetching its attributes from Octokit" do
        let(:pull) { PullRequest.new repo_name, pr_number }

        before do
          pull.stub(data: octo)
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
            GitHub::User.stub(:new).with("pbyrne").and_return(stub(:author_name => "pbyrne"))
            GitHub::User.stub(:new).with("anfleene").and_return(stub(:author_name => "anfleene"))
          end

          it "returns the names of the commit authors" do
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
            pull.exclude_octopolo_user(users).should_not include("tst-octopolo")
            pull.exclude_octopolo_user(users).should include("anfleene")
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
        let(:data) { stub(:data)}
        let(:creator) { stub(:pull_request_creator, number: number, data: data)}
        let(:pull_request) { stub(:pull_request) }

        it "passes on to PullRequestCreator and returns a new PullRequest" do
          PullRequestCreator.should_receive(:perform).with(repo_name, options) { creator }
          PullRequest.should_receive(:new).with(repo_name, number, data) { pull_request }
          PullRequest.create(repo_name, options).should == pull_request
        end
      end

      context ".current" do
        let(:branch_name) { "branch-name" }
        let(:error_message) { "some error message" }
        let(:pull) { PullRequest.new repo_name, pr_number }

        before do
          Octopolo.config.stub(:github_repo) { repo_name }
        end

        it "calls GitHub.pull_requests with the current repo/branch and return a single pull request" do
          Git.should_receive(:current_branch) { branch_name }
          GitHub.should_receive(:search_issues).and_return(double(total_count: 1, items: [pull]))
          PullRequest.current.should == pull
        end

        it "returns nil when Git.current_branch fails" do
          Git.should_receive(:current_branch) { raise error_message }
          CLI.should_receive(:say).with("An error occurred while getting the current branch: #{error_message}")
          PullRequest.current.should == nil
        end

        it "returns nil when GitHub.pull_requests fails" do
          Git.should_receive(:current_branch) { branch_name }
          GitHub.should_receive(:search_issues) { raise error_message }
          CLI.should_receive(:say).with("An error occurred while getting the current branch: #{error_message}")
          PullRequest.current.should == nil
        end

        it "returns nil when more than one PR exists" do
          Git.should_receive(:current_branch) { branch_name }
          GitHub.should_receive(:search_issues).and_return(double(total_count: 2, items: [pull, pull]))
          CLI.should_receive(:say).with("Multiple pull requests found for branch #{branch_name}")
          PullRequest.current.should == nil
        end

        it "returns nil when no PR exists" do
          Git.should_receive(:current_branch) { branch_name }
          GitHub.should_receive(:search_issues).and_return(double(total_count: 0, items: []))
          CLI.should_receive(:say).with("No pull request found for branch #{branch_name}")
          PullRequest.current.should == nil
        end

      end

      context "labeling" do
        let(:label1) { Label.new(name: "low-risk", color: "343434") }
        let(:label2) { Label.new(name: "high-risk", color: '565656') }
        let(:pull_request) { PullRequest.new repo_name, pr_number }

        context "#add_labels" do
          it "sends the correct arguments to add_labels_to_pull for multiple labels" do
            allow(Label).to receive(:build_label_array) {[label1,label2]}
            expect(GitHub).to receive(:add_labels_to_issue).with(repo_name, pr_number, ["low-risk","high-risk"])
            pull_request.add_labels([label1, label2])
          end

          it "sends the correct arguments to add_labels_to_pull for a single label" do
            allow(Label).to receive(:build_label_array) {[label1]}
            expect(GitHub).to receive(:add_labels_to_issue).with(repo_name, pr_number, ["low-risk"])
            pull_request.add_labels(label1)
          end
        end

        context "#remove_from_pull" do

          it "sends the correct arguments to remove_label" do
            allow(Label).to receive(:build_label_array) {[label1]}
            expect(GitHub).to receive(:remove_label).with(repo_name, pr_number, "low-risk")
            pull_request.remove_labels(label1)
          end

          it "calls remove_label only once" do
            allow(Label).to receive(:build_label_array) {[label1]}
            expect(GitHub).to receive(:remove_label).once
            pull_request.remove_labels(label1)
          end

          it "calls remove_label twice" do
            allow(Label).to receive(:build_label_array) {[label1, label2]}
            expect(GitHub).to receive(:remove_label).twice
            pull_request.remove_labels([label1,label2])
          end
        end
      end
    end
  end
end
