require "spec_helper"
require_relative "../../../lib/octopolo/github"

module Octopolo
  module GitHub
    describe PullRequest do
      let(:repo_name) { "account/repo" }
      let(:pr_number) { 7 }
      let(:prhash) { double }
      let(:commits) { double }
      let(:comments) { double }
      let(:octo) { double }

      context ".new" do
        it "remembers the pull request identifiers" do
          pr = PullRequest.new repo_name, pr_number
          expect(pr.repo_name).to eq(repo_name)
          expect(pr.number).to eq(pr_number)
        end

        it "optionally accepts the github data" do
          pr = PullRequest.new repo_name, pr_number, octo
          expect(pr.data).to eq(octo)
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
          expect(GitHub).to receive(:pull_request).with(pull.repo_name, pull.number) { octo }
          expect(pull.data).to eq(octo)
        end

        it "catches the information" do
          expect(GitHub).to receive(:pull_request).once { octo }
          pull.data
          pull.data
        end

        it "fails if given invalid information" do
          expect(GitHub).to receive(:pull_request).and_raise(Octokit::NotFound)
          expect { pull.data }.to raise_error(PullRequest::NotFound)
        end
      end

      context "fetching its attributes from Octokit" do
        let(:pull) { PullRequest.new repo_name, pr_number }

        before do
          allow(pull).to receive_messages(data: octo)
        end

        context "#title" do
          let(:octo) { double(title: "the title") }

          it "retrieves from the github data" do
            expect(pull.title).to eq(octo.title)
          end
        end

        context "#branch" do
          let(:octo) { double(head: double(ref: "asdf")) }

          it "retrieves from the github data" do
            expect(pull.branch).to eq(octo.head.ref)
          end
        end

        context "#commits" do
          it "fetches through octokit" do
            expect(Commit).to receive(:for_pull_request).with(pull) { commits }
            expect(pull.commits).to eq(commits)
          end

          it "caches the result" do
            expect(Commit).to receive(:for_pull_request).once { commits }
            pull.commits
            pull.commits
          end
        end

        context "#comments" do
          it "fetches through octokit" do
            expect(GitHub).to receive(:issue_comments).with(pull.repo_name, pull.number) { comments }
            expect(pull.comments).to eq(comments)
          end

          it "caches the result" do
            expect(GitHub).to receive(:issue_comments).once { comments }
            pull.comments
            pull.comments
          end
        end

        context "#author_names" do
          let(:commit1) { double(author_name: "foo") }
          let(:commit2) { double(author_name: "bar") }

          before do
            allow(pull).to receive_messages(commits: [commit1, commit2])
          end

          it "returns the list of authors" do
            names = pull.author_names
            expect(names).not_to be_empty
            expect(names.count).to eq(2)
            expect(names.first).to eq("foo")
          end

          it "returns only unique values" do
            # make it same commenter
            allow(commit2).to receive_messages(author_name: commit1.author_name)
            names = pull.author_names
            expect(names.size).to eq(1)
          end
        end

        context "#commenter_names" do
          let(:comment1) { double(user: double(login: "pbyrne")) }
          let(:comment2) { double(user: double(login: "anfleene")) }

          before do
            allow(pull).to receive_messages(comments: [comment1, comment2], author_names: [])
            allow(GitHub::User).to receive(:new).with("pbyrne").and_return(double(:author_name => "pbyrne"))
            allow(GitHub::User).to receive(:new).with("anfleene").and_return(double(:author_name => "anfleene"))
          end

          it "returns the names of the commit authors" do
            names = pull.commenter_names
            expect(names).not_to be_empty
            expect(names.size).to eq(2)
            expect(names.first).to eq("pbyrne")
          end

          it "returns only unique values" do
            # make it same commenter
            allow(comment2.user).to receive_messages(login: comment1.user.login)
            names = pull.commenter_names
            expect(names.size).to eq(1)
          end

          it "does not include authors in this list" do
            allow(pull).to receive_messages(author_names: [comment1.user.login])
            names = pull.commenter_names
            expect(names.size).to eq(1)
            expect(names).not_to include comment1.user.login
          end
        end

        context "#without_octopolo_users" do
          let(:users) { ["anfleene", "tst-octopolo"] }

          it "excludes the github octopolo users" do
            expect(pull.exclude_octopolo_user(users)).not_to include("tst-octopolo")
            expect(pull.exclude_octopolo_user(users)).to include("anfleene")
          end
        end

        context "#url" do
          let(:octo) { double(html_url: "http://example.com") }

          it "retrieves from the github data" do
            expect(pull.url).to eq(octo.html_url)
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
            allow(pull).to receive_messages(body: body)
          end

          it "parses from the body" do
            urls = pull.external_urls
            expect(urls.size).to eq(3)
            expect(urls).to include "http://thedesk.tstmedia.com/admin.php?pg=request&reqid=44690"
            expect(urls).to include "http://thedesk.tstmedia.com/admin.php?pg=request&reqid=44693"
            expect(urls).to include "http://www.ngin.com.stage.ngin-staging.com/api/volleyball/stats/summaries?id=68382&gender=girls&tst_test=1&date=8/24/2012"
          end
        end

        context "#body" do
          let(:octo) { double(body: "asdf") }

          it "retrieves from the github data" do
            expect(pull.body).to eq(octo.body)
          end

          it "returns an empty string if the GitHub data has no body" do
            allow(octo).to receive_messages(body: nil)
            expect(pull.body).to eq("")
          end
        end

        context "#mergeable?" do
          it "retrieves from the github data" do
            allow(octo).to receive_messages(mergeable: true)
            expect(pull).to be_mergeable
            allow(octo).to receive_messages(mergeable: false)
            expect(pull).not_to be_mergeable
          end
        end

        context "#week" do
          it "retrieves from the github data" do
            allow(octo).to receive_messages(closed_at: "2012-09-18T14:00:01Z")
            expect(pull.week).to eq(Week.parse(octo.closed_at))
          end
        end
      end

      context "#human_app_name" do
        let(:repo_name) { "account_name/repo_name" }
        let(:pull) { PullRequest.new repo_name, pr_number }

        it "infers from the repo_name" do
          pull.repo_name = "account/foo"
          expect(pull.human_app_name).to eq("Foo")
          pull.repo_name = "account/foo_bar"
          expect(pull.human_app_name).to eq("Foo Bar")
        end
      end

      context ".closed repo_name" do
        let(:raw_pr) { double(:octo_data, number: 123) }
        let(:pr_wrapper) { double(:pull_request) }

        it "crawls the repo for pull requests and wraps them in PullRequests" do
          expect(GitHub).to receive(:pull_requests).with(repo_name, "closed") { [raw_pr] }
          expect(PullRequest).to receive(:new).with(repo_name, raw_pr.number, raw_pr) { pr_wrapper }

          result = PullRequest.closed(repo_name)
          expect(result).to eq([pr_wrapper])
        end
      end

      context "#write_comment(message)" do
        let(:pull) { PullRequest.new repo_name, pr_number }
        let(:message) { "Test message" }
        let(:error) { Octokit::UnprocessableEntity.new }

        it "creates the message through octokit" do
          expect(GitHub).to receive(:add_comment).with(pull.repo_name, pull.number, ":octocat: #{message}")

          pull.write_comment message
        end

        it "raises CommentFailed if an exception occurs" do
          expect(GitHub).to receive(:add_comment).and_raise(error)

          expect { pull.write_comment message }.to raise_error(PullRequest::CommentFailed, "Unable to write the comment: '#{error.message}'")
        end
      end

      context ".create repo_name, options" do
        let(:options) { double(:hash) }
        let(:number) { double(:integer) }
        let(:data) { double(:data)}
        let(:creator) { double(:pull_request_creator, number: number, data: data)}
        let(:pull_request) { double(:pull_request) }

        it "passes on to PullRequestCreator and returns a new PullRequest" do
          expect(PullRequestCreator).to receive(:perform).with(repo_name, options) { creator }
          expect(PullRequest).to receive(:new).with(repo_name, number, data) { pull_request }
          expect(PullRequest.create(repo_name, options)).to eq(pull_request)
        end
      end

      context ".current" do
        let(:branch_name) { "branch-name" }
        let(:error_message) { "some error message" }
        let(:pull) { PullRequest.new repo_name, pr_number }

        before do
          allow(Octopolo.config).to receive(:github_repo) { repo_name }
        end

        it "calls GitHub.pull_requests with the current repo/branch and return a single pull request" do
          expect(Git).to receive(:current_branch) { branch_name }
          expect(CLI).to receive(:say).with("Pull request for current branch is number #{pr_number}")
          expect(GitHub).to receive(:search_issues) { double(total_count: 1, items: [pull]) }
          expect(PullRequest.current).to eq(pull)
        end

        it "returns nil when Git.current_branch fails" do
          expect(Git).to receive(:current_branch) { raise error_message }
          expect(CLI).to receive(:say).with("An error occurred while getting the current branch: #{error_message}")
          expect(PullRequest.current).to eq(nil)
        end

        it "returns nil when GitHub.pull_requests fails" do
          expect(Git).to receive(:current_branch) { branch_name }
          expect(GitHub).to receive(:search_issues) { raise error_message }
          expect(CLI).to receive(:say).with("An error occurred while getting the current branch: #{error_message}")
          expect(PullRequest.current).to eq(nil)
        end

        it "returns nil when more than one PR exists" do
          expect(Git).to receive(:current_branch) { branch_name }
          expect(GitHub).to receive(:search_issues) { double(total_count: 2, items: [pull, pull]) }
          expect(CLI).to receive(:say).with("Multiple pull requests found for branch #{branch_name}")
          expect(PullRequest.current).to eq(nil)
        end

        it "returns nil when no PR exists" do
          expect(Git).to receive(:current_branch) { branch_name }
          expect(GitHub).to receive(:search_issues) { double(total_count: 0, items: []) }
          expect(CLI).to receive(:say).with("No pull request found for branch #{branch_name}")
          expect(PullRequest.current).to eq(nil)
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
