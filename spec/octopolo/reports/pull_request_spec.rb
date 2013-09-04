require "spec_helper"
require "automation/reports/pull_request"

module Automation
  module Reports
    describe PullRequest do
      context ".perform number_of_weeks" do
        let(:report) { stub }
        let(:output) { stub }
        let(:number_of_weeks) { 5 }

        it "initializes a new report and performs it" do
          PullRequest.should_receive(:new).with(number_of_weeks) { report }
          report.should_receive(:perform) { output }

          PullRequest.perform(number_of_weeks).should == output
        end
      end

      context ".new number_of_weeks" do
        let(:number_of_weeks) { 4 }

        it "remembers the number of weeks to run for" do
          report = PullRequest.new number_of_weeks
          report.number_of_weeks.should == number_of_weeks
        end
      end

      context "#perform" do
        let(:reporter) { PullRequest.new 3 }
        let(:report_output) { stub }

        it "collects the pull requests and outputs an array for CSV" do
          reporter.should_receive(:gather_pull_requests)
          reporter.should_receive(:purge_old_pull_requests)
          reporter.should_receive(:output_for_csv) { report_output }

          reporter.perform.should == report_output
        end
      end

      context "#gather_pull_requests" do
        let(:reporter) { PullRequest.new 3 }
        let(:foorepo) { "tstmedia/foo" }
        let(:barrepo) { "tstmedia/bar" }
        let(:foopr1) { stub }
        let(:foopr2) { stub }
        let(:barpr) { stub }

        before do
          reporter.stub(repo_names: [foorepo, barrepo])
        end

        # TODO consider refactoring, this is getting pretty smelly
        it "captures pull requests" do
          reporter.pull_requests.should be_empty

          GitHub::PullRequest.should_receive(:closed).with(foorepo) { [foopr1, foopr2] }
          GitHub::PullRequest.should_receive(:closed).with(barrepo) { [barpr] }
          reporter.gather_pull_requests
          pulls = reporter.pull_requests

          pulls.should_not be_empty
          pulls.should include foopr1
          pulls.should include foopr2
          pulls.should include barpr
        end
      end

      context "#purge_old_pull_requests" do
        let(:reporter) { PullRequest.new 2 }
        let(:old_pr) { stub(week: oldweek) }
        let(:current_pr) { stub(week: currentweek) }
        let(:oldweek) { stub }
        let(:currentweek) { stub }

        before do
          reporter.stub(weeks: [currentweek])
          reporter.pull_requests = [old_pr, current_pr]
        end

        it "removes any pull request not in its reported weeks" do
          reporter.pull_requests.should include old_pr
          reporter.pull_requests.should include current_pr

          reporter.purge_old_pull_requests

          reporter.pull_requests.should include current_pr
          reporter.pull_requests.should_not include old_pr
        end
      end

      context "#repo_names" do
        let(:reporter) { PullRequest.new 3 }
        let(:repo1) { stub(full_name: "tstmedia/foo") }
        let(:repo2) { stub(full_name: "tstmedia/bar") }

        before do
          GitHub.stub(org_repos: [repo1, repo2])
        end

        it "returns the full names of the TST repos" do
          reporter.repo_names.should_not be_empty
          reporter.repo_names.should include repo1.full_name
          reporter.repo_names.should include repo2.full_name
        end
      end

      context "#output_for_csv" do
        let(:reporter) { PullRequest.new 2 }
        let(:headers) { stub }
        let(:row1) { stub }
        let(:row2) { stub }

        it "gathers together the headers and the rows" do
          reporter.stub({
            header_row: headers,
            content_rows: [row1, row2]
          })

          reporter.output_for_csv.should_not be_empty
          reporter.output_for_csv.first.should == headers
          reporter.output_for_csv.should include row1
          reporter.output_for_csv.should include row2
        end
      end

      context "#header_row" do
        let(:reporter) { PullRequest.new 4 }

        subject { reporter.header_row }

        it "outputs the given number of weeks" do
          subject.count.should == reporter.number_of_weeks + 1
          subject[0].should == "Commiters"
          subject[1].should == reporter.weeks.first
          reporter.weeks.each do |week|
            subject.should include week
          end
        end
      end

      context "#weeks" do
        it "returns the last N weeks for its count" do
          reporter = PullRequest.new 3
          reporter.weeks.should == Week.last(reporter.number_of_weeks)
        end
      end

      context "#content_rows" do
        let(:reporter) { PullRequest.new 2 }
        let(:week1) { stub }
        let(:week2) { stub }
        let(:author1) { stub }
        let(:author2) { stub }

        before do
          reporter.stub({
            author_names: [author1, author2],
            weeks: [week1, week2],
          })
        end

        it "loops through authors and counts the pull requests on the report's weeks" do
          reporter.should_receive(:pull_request_count).with(author1, week1) { 1 }
          reporter.should_receive(:pull_request_count).with(author1, week2) { 4 }
          reporter.should_receive(:pull_request_count).with(author2, week1) { 2 }
          reporter.should_receive(:pull_request_count).with(author2, week2) { 3 }

          result = reporter.content_rows
          result.count.should == reporter.author_names.count
          result[0].should == [author1, 1, 4]
          result[1].should == [author2, 2, 3]
        end
      end

      context "#author_names" do
        let(:name1) { "joe" }
        let(:name2) { "bob" }
        let(:name3) { "sally" }
        let(:pull1) { stub(author_names: [name1, name2]) }
        let(:pull2) { stub(author_names: [name2, name3]) }
        let(:reporter) { PullRequest.new 1 }

        before do
          reporter.pull_requests = [pull1, pull2]
        end

        it "returns author names for all pull requests" do
          reporter.author_names.should_not be_empty
          reporter.author_names.should include name1
          reporter.author_names.should include name2
          reporter.author_names.should include name3
        end

        it "returns no duplicates" do
          reporter.author_names.count.should == 3
        end
      end

      context "#pull_request_count author, week" do
        let(:reporter) { PullRequest.new 1 }
        let(:week) { stub }
        let(:author) { stub }
        let(:pr1) { stub }
        let(:pr2) { stub }

        it "returns the count of the pull requests by that author in the given week" do
          reporter.should_receive(:filtered_pull_requests).with(author, week) { [pr1, pr2] }
          reporter.pull_request_count(author, week).should == 2
        end
      end

      context "#filtered_pull_requests author, week" do
        let(:reporter) { PullRequest.new 1 }
        let(:author) { stub }
        let(:other_author) { stub }
        let(:week) { stub }
        let(:other_week) { stub }
        let(:pr_match) { stub(:pull_request, week: week, author_names: [author]) }
        let(:pr_wrong_author) { stub(:pull_request, week: week, author_names: [other_author]) }
        let(:pr_wrong_week) { stub(:pull_request, week: other_week, author_names: [author]) }

        subject { reporter.filtered_pull_requests author, week }

        before do
          reporter.pull_requests = [pr_match, pr_wrong_author, pr_wrong_week]
        end

        it "returns only pull requests for the given author and week" do
          subject.should_not be_empty
          subject.should include pr_match
          subject.should_not include pr_wrong_week
          subject.should_not include pr_wrong_author
        end
      end
    end
  end
end
