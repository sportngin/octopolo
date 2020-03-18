require "spec_helper"
require_relative "../../lib/octopolo/git"

module Octopolo
  describe Git do
    let(:cli) { double(:CLI) }

    context ".perform(subcommand)" do
      let(:command) { "status" }

      before { Git.cli = cli }

      it "performs the given subcommand" do
        expect(cli).to receive(:perform).with("git #{command}", true, false)
        Git.perform command
      end
    end

    context ".perform_quietly(subcommand)" do
      let(:command) { "status" }

      before { Git.cli = cli }

      it "performs the given subcommand quietly" do
        expect(cli).to receive(:perform_quietly).with("git #{command}")
        Git.perform_quietly command
      end
    end

    context ".current_branch" do
      let(:name) { "foo" }
      let(:output) { "#{name}\n" }
      let(:nobranch_output) { "#{Git::NO_BRANCH}\n" }
      before { Git.cli = cli }

      it "performs a command to filter current branch from list of branches" do
        expect(cli).to receive(:perform_quietly).with("git branch | grep '^* ' | cut -c 3-") { output }
        expect(Git.current_branch).to eq(name)
      end

      it "raises NotOnBranch if not on a branch" do
        expect(cli).to receive(:perform_quietly) { nobranch_output }
        expect { Git.current_branch }.to raise_error(Git::NotOnBranch, "Not currently checked out to a particular branch")
      end

      it "staging and deploy should be reserved branches" do
        allow(Git).to receive(:current_branch).and_return "staging.05.12"
        expect(Git.reserved_branch?).to be_truthy

        allow(Git).to receive(:current_branch).and_return "deployable.05.12"
        expect(Git.reserved_branch?).to be_truthy

        allow(Git).to receive(:current_branch).and_return "qaready.05.12"
        expect(Git.reserved_branch?).to be_truthy
      end

      it "other branches should not be reserved branches" do
        allow(Git).to receive(:current_branch).and_return "not_staging.05.12"
        expect(Git.reserved_branch?).not_to be_truthy

        allow(Git).to receive(:current_branch).and_return "not_deployable.05.12"
        expect(Git.reserved_branch?).not_to be_truthy

        allow(Git).to receive(:current_branch).and_return "not_qaready.05.12"
        expect(Git.reserved_branch?).not_to be_truthy
      end
    end



    context ".check_out(branch_name)" do
      let(:name) { "foo" }

      it "checks out the given branch name" do
        expect(Git).to receive(:fetch)
        expect(Git).to receive(:perform).with("checkout #{name}")
        expect(Git).to receive(:pull)
        expect(Git).to receive(:current_branch) { name }
        Git.check_out name
      end

      it "checks out the given branch name without after pull" do
        expect(Git).to receive(:fetch)
        expect(Git).to receive(:perform).with("checkout #{name}")
        expect(Git).not_to receive(:pull)
        expect(Git).to receive(:current_branch) { name }
        Git.check_out(name, false)
      end

      it "raises an exception if the current branch is not the requested branch afterward" do
        expect(Git).to receive(:fetch)
        expect(Git).to receive(:perform)
        expect(Git).to receive(:pull)
        expect(Git).to receive(:current_branch) { "other" }
        expect { Git.check_out name }.to raise_error(Git::CheckoutFailed, "Failed to check out '#{name}'")
      end
    end

    context ".clean?" do
      let(:cmd) { "git status --short" }

      before { Git.cli = cli }

      it "returns true if everything is checked in" do
        expect(cli).to receive(:perform_quietly).with(cmd) { "" }
        expect(Git).to be_clean
      end

      it "returns false if the index has untracked files" do
        expect(cli).to receive(:perform_quietly).with(cmd) { "?? foo.txt" }
        expect(Git).not_to be_clean
      end

      it "returns false if the index has missing files" do
        expect(cli).to receive(:perform_quietly).with(cmd) { "D foo.txt" }
        expect(Git).not_to be_clean
      end

      it "returns false if the index has changed files" do
        expect(cli).to receive(:perform_quietly).with(cmd) { "M foo.txt" }
        expect(Git).not_to be_clean
      end
    end

    context ".if_clean" do
      let(:custom_message) { "Some other message" }

      before { Git.cli = cli }

      it "performs the block if the git index is clean" do
        expect(Git).to receive(:clean?) { true }
        expect(Math).to receive(:log).with(1)

        Git.if_clean do
          Math.log 1
        end
      end

      it "performs the block if the git index is not clean and user responds yes" do
        expect(Git).to receive(:clean?) { false }
        expect(cli).to receive(:ask_boolean).with(Git::DIRTY_CONFIRM_MESSAGE) { true }
        expect(Math).to receive(:log).with(1)

        Git.if_clean do
          Math.log 1
        end
      end

      it "does not perform the block if the git index is not clean and user responds no" do
        expect(Git).to receive(:clean?) { false }
        expect(cli).to receive(:ask_boolean).with(Git::DIRTY_CONFIRM_MESSAGE) { false}
        expect(Math).not_to receive(:log)
        expect(Git).to receive(:alert_dirty_index).with(Git::DEFAULT_DIRTY_MESSAGE)


        expect do
          Git.if_clean do
            Math.log 1
          end
        end.to raise_error(SystemExit)
      end

      it "prints a custom message if git index is not clean and user responds no" do
        expect(Git).to receive(:clean?) { false }
        expect(cli).to receive(:ask_boolean).with(Git::DIRTY_CONFIRM_MESSAGE) { false }
        expect(Math).not_to receive(:log)
        expect(Git).to receive(:alert_dirty_index).with(custom_message)

        expect do
          Git.if_clean custom_message do
            Math.log 1
          end
        end.to raise_error(SystemExit)
      end
    end

    context ".alert_dirty_index(message)" do
      let(:message) { "Some message" }

      before { Git.cli = cli }

      it "prints the given message and shows the git status" do
        expect(cli).to receive(:say).with(" ")
        expect(cli).to receive(:say).with(message)
        expect(cli).to receive(:say).with(" ")
        expect(Git).to receive(:perform).with("status")

        expect{Git.alert_dirty_index message}.to raise_error
      end
    end

    context ".merge(branch_name)" do
      let(:branch_name) { "foo" }

      it "fetches the latest code and merges the given branch name" do
        expect(Git).to receive(:if_clean).and_yield
        expect(Git).to receive(:fetch)
        expect(Git).to receive(:perform).with("merge --no-ff origin/#{branch_name}", :ignore_non_zero => true)
        expect(Git).to receive(:clean?).twice { true }
        expect(Git).to receive(:push)

        Git.merge branch_name
      end

      it "does not push and raises MergeFailed if the merge failed" do
        expect(Git).to receive(:if_clean).and_yield
        expect(Git).to receive(:fetch)
        expect(Git).to receive(:perform).with("merge --no-ff origin/#{branch_name}", :ignore_non_zero => true)
        expect(Git).to receive(:clean?).twice { false }
        expect(Git).not_to receive(:push)

        expect { Git.merge branch_name }.to raise_error(Git::MergeFailed)
      end
    end

    context ".fetch" do
      it "fetches and prunes remote branches" do
        expect(Git).to receive(:perform_quietly).with("fetch --prune")

        Git.fetch
      end
    end

    context ".push" do
      let(:branch) { "current_branch" }

      it "pushes the current branch" do
        allow(Git).to receive_messages(current_branch: branch)
        expect(Git).to receive(:if_clean).and_yield
        expect(Git).to receive(:perform).with("push origin #{branch}")

        Git.push
      end
    end

    context ".pull" do
      it "performs a pull if the index is clean" do
        expect(Git).to receive(:if_clean).and_yield
        expect(Git).to receive(:perform).with("pull")
        Git.pull
      end
    end

    context ".remote_branches" do
      let(:raw_output) { raw_names.join("\n  ") }
      let(:raw_names) { %w(origin/foo origin/bar) }
      let(:cleaned_names) { %w(foo bar) }

      it "prunes the remote branch list and grabs all the branch names" do
        expect(Git).to receive(:fetch)
        expect(Git).to receive(:perform_quietly).with("branch --remote") { raw_output }
        expect(Git.remote_branches).to eq(cleaned_names.sort)
      end
    end

    context ".branches_for branch_type" do
      let(:remote_branches) { [depl1, rando, stage1, depl2].sort }
      let(:depl1) { "deployable.12.20" }
      let(:depl2) { "deployable.11.05" }
      let(:stage1) { "staging.04.05" }
      let(:rando) { "something-else" }

      before do
        expect(Git).to receive(:remote_branches) { remote_branches }
      end

      it "can find deployable branches" do
        deployables = Git.branches_for(Git::DEPLOYABLE_PREFIX)
        expect(deployables).to include depl1
        expect(deployables).to include depl2
        expect(deployables).to eq([depl1, depl2].sort)
        expect(deployables.count).to eq(2)
      end

      it "can find staging branches" do
        stagings = Git.branches_for(Git::STAGING_PREFIX)
        expect(stagings).to include stage1
        expect(stagings.count).to eq(1)
      end
    end

    context ".deployable_branch" do
      let(:depl1) { "deployable.12.05" }
      let(:depl2) { "deployable.12.25" }

      it "returns the last deployable branch" do
        expect(Git).to receive(:branches_for).with(Git::DEPLOYABLE_PREFIX) { [depl1, depl2] }
        expect(Git.deployable_branch).to eq(depl2)
      end

      it "raises an exception if none exist" do
        expect(Git).to receive(:branches_for).with(Git::DEPLOYABLE_PREFIX) { [] }
        expect { expect(Git.deployable_branch).to }.to raise_error(Git::NoBranchOfType, "No #{Git::DEPLOYABLE_PREFIX} branch")
      end
    end

    context ".staging_branch" do
      let(:stage1) { "stage1" }
      let(:stage2) { "stage2" }

      it "returns the last staging branch" do
        expect(Git).to receive(:branches_for).with(Git::STAGING_PREFIX) { [stage1, stage2] }
        expect(Git.staging_branch).to eq(stage2)
      end

      it "raises an exception if none exist" do
        expect(Git).to receive(:branches_for).with(Git::STAGING_PREFIX) { [] }
        expect { Git.staging_branch}.to raise_error(Git::NoBranchOfType, "No #{Git::STAGING_PREFIX} branch")
      end
    end

    context ".qaready_branch" do
      let(:qaready1) { "qaready1" }
      let(:qaready2) { "qaready2" }

      it "returns the last qaready branch" do
        expect(Git).to receive(:branches_for).with(Git::QAREADY_PREFIX) { [qaready1, qaready2] }
        expect(Git.qaready_branch).to eq(qaready2)
      end

      it "raises an exception if none exist" do
        expect(Git).to receive(:branches_for).with(Git::QAREADY_PREFIX) { [] }
        expect { Git.qaready_branch }.to raise_error(Git::NoBranchOfType, "No #{Git::QAREADY_PREFIX} branch")
      end
    end

    context ".release_tags" do
      let(:valid1) { "2012.02.28" }
      let(:valid2) { "2012.11.10" }
      let(:invalid) { "foothing" }
      let(:tags) { [valid1, invalid, valid2].join("\n") }

      it "returns all the tags for releases" do
        expect(Git).to receive(:perform_quietly).with("tag") { tags }
        release_tags = Git.release_tags
        expect(release_tags).not_to include invalid
        expect(release_tags).to include valid1
        expect(release_tags).to include valid2
      end
    end

    context ".recent_release_tags" do
      let(:long_list) { Array.new(100, "sometag#{rand(1000)}") } # big-ass list

      it "returns the last #{Git::RECENT_TAG_LIMIT} tags" do
        expect(Git).to receive(:release_tags) { long_list }
        tags = Git.recent_release_tags
        expect(tags.count).to eq(Git::RECENT_TAG_LIMIT)
        expect(tags).to eq(long_list.last(Git::RECENT_TAG_LIMIT))
      end
    end

    context ".semver_tags" do
      let(:valid1) { "0.0.1" }
      let(:valid2) { "v0.0.3" }
      let(:invalid) { "foothing" }
      let(:tags) { [valid1, invalid, valid2].join("\n") }

      it "returns all the tags set as a sematic version" do
        expect(Git).to receive(:perform_quietly).with("tag") { tags }
        release_tags = Git.semver_tags
        expect(release_tags).not_to include invalid
        expect(release_tags).to include valid1
        expect(release_tags).to include valid2
      end
    end

    context ".new_branch(new_branch_name, source_branch_name)" do
      let(:new_branch_name) { "foo" }
      let(:source_branch_name) { "bar" }

      it "creates and pushes a new branch from the source branch" do
        expect(Git).to receive(:fetch)
        expect(Git).to receive(:perform).with("branch --no-track #{new_branch_name} origin/#{source_branch_name}")
        expect(Git).to receive(:check_out).with(new_branch_name, false)
        expect(Git).to receive(:perform).with("push --set-upstream origin #{new_branch_name}")

        Git.new_branch(new_branch_name, source_branch_name)
      end
    end

    context ".new_tag(tag_name)" do
      let(:tag) { "asdf" }

      it "creates a new tag with the given name and pushes it" do
        expect(Git).to receive(:perform).with("tag #{tag}")
        expect(Git).to receive(:push)
        expect(Git).to receive(:perform).with("push --tag")

        Git.new_tag(tag)
      end
    end

    context ".stale_branches(destination_branch, branches_to_ignore)" do
      let(:ignored) { %w(foo bar) }
      let(:branch_name) { "master" }
      let(:sha) { "asdf123" }
      let(:raw_result) do
        %Q(
          origin/bing
          origin/bang
        )
      end

      it "checks for stale branches for the given branch, less branches to ignore" do
        expect(Git).to receive(:fetch)
        expect(Git).to receive(:stale_branches_to_ignore).with(ignored) { ignored }
        expect(Git).to receive(:recent_sha).with(branch_name) { sha }
        expect(Git).to receive(:perform_quietly).with("branch --remote --merged #{sha} | grep -E -v '(foo|bar)'") { raw_result }

        expect(Git.stale_branches(branch_name, ignored)).to eq(%w(bing bang))
      end

      it "defaults to master branch and no extra branches to ignore" do
        expect(Git).to receive(:fetch)
        expect(Git).to receive(:stale_branches_to_ignore).with([]) { ignored }
        expect(Git).to receive(:recent_sha).with("master") { sha }
        expect(Git).to receive(:perform_quietly).with("branch --remote --merged #{sha} | grep -E -v '(foo|bar)'") { raw_result }

        Git.stale_branches
      end
    end

    context "#branches_to_ignore(custom_branch_list)" do
      it "ignores some branches by default" do
        expect(Git.send(:stale_branches_to_ignore)).to include "HEAD"
        expect(Git.send(:stale_branches_to_ignore)).to include "master"
        expect(Git.send(:stale_branches_to_ignore)).to include "staging"
        expect(Git.send(:stale_branches_to_ignore)).to include "deployable"
      end

      it "accepts an optional list of additional branches to ignore" do
        expect(Git.send(:stale_branches_to_ignore, ["foo"])).to include "HEAD"
        expect(Git.send(:stale_branches_to_ignore, ["foo"])).to include "master"
        expect(Git.send(:stale_branches_to_ignore, ["foo"])).to include "staging"
        expect(Git.send(:stale_branches_to_ignore, ["foo"])).to include "deployable"
        expect(Git.send(:stale_branches_to_ignore, ["foo"])).to include "foo"
      end
    end

    context "#recent_sha(branch_name)" do
      let(:branch_name) { "foo" }
      let(:raw_sha) { "asdf123\n" }

      it "grabs the SHA of the given branch from 1 day ago" do
        expect(Git).to receive(:perform_quietly).with("rev-list `git rev-parse remotes/origin/#{branch_name} --before=1.day.ago` --max-count=1") { raw_sha }
        expect(Git.send(:recent_sha, branch_name)).to eq("asdf123")
      end
    end

    context ".delete_branch(branch_name)" do
      let(:branch_name) { "foo" }

      it "leverages git-extra's delete-branch command" do
        expect(Git).to receive(:perform).with("push origin :#{branch_name}")
        expect(Git).to receive(:perform).with("branch -D #{branch_name}", :ignore_non_zero => true)
        Git.delete_branch branch_name
      end
    end
  end
end
