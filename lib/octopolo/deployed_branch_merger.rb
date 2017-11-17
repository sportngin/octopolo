require_relative 'pull_request_merger'

module Octopolo
  class DeployedBranchMerger
    include ConfigWrapper
    include CLIWrapper

    attr_reader :branch_type, :should_remerge_deployed_prs
    attr_accessor :remerge_pr_numbers

    def initialize(branch_type, should_remerge_deployed_prs = false)
      @branch_type = branch_type
      @should_remerge_deployed_prs = should_remerge_deployed_prs
    end

    def merge
      return unless can_remerge_branches?

      if should_remerge_deployed_prs
        merge_all
      else
        remerge_dialog
      end

      return if remerge_pr_numbers.empty?
      remerge_pr_numbers.each do |pr_number|
        Octopolo::PullRequestMerger.new(branch_type, pr_number).perform
      end
    end

    def remerge_dialog
      cli.say('Deployed PRs:')
      cli.say(deployed_prs.map { |pr| "[#{pr.number}] #{pr.title} - #{pr.html_url}" }.join("\n"))
      cli.highline.choose do |menu|
        menu.prompt = 'Would you like to re-merge deployed PRs?'
        menu.choice(:none) { @remerge_pr_numbers = [] }
        menu.choice(:all) { merge_all }
        # menu.choice(:choose) {  }
      end
    end

    def merge_all
      @remerge_pr_numbers = deployed_prs.map(&:number)
    end

    def can_remerge_branches?
      branch_type == Git::STAGING_PREFIX
    end

    def deployed_prs
      @deployed_prs ||= Octopolo::GitHub
                        .search_issues("repo:#{config.github_repo} type:pr is:open label:#{deployed_label}")
                        .items
    end

    def deployed_label
      "deployed-to-#{branch_type}"
    end
  end
end
