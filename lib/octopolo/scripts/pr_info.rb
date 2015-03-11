require_relative "../scripts"
require_relative "../github"

module Octopolo
  module Scripts
    class PrInfo
      include CLIWrapper
      include ConfigWrapper
      include GitWrapper

      attr_accessor :repo, :options

      def self.execute(repo, options)
        new(repo, options).execute
        end

      def initialize(repo, options)
        @repo = repo
        @options = options
      end

      def execute
        GitHub.connect do
          if options[:open]
            get_pull_requests("open")
          elsif options[:branch]
            get_pull_requests("all", options[:branch])
          elsif options[:num]
            get_branch_name(options[:num])
          elsif options[:raw_arg]
            if is_int?(options[:raw_arg])
              get_branch_name(options[:raw_arg])
            else
              get_pull_requests("all", options[:raw_arg])
            end
          else
            get_pull_requests("all", Git.current_branch)
          end
        end
      end

      def get_branch_name(pr_num)
        pr = GitHub.pull_request(repo, pr_num)
        print_pr(pr, pr["head"]["ref"])
      end

      def get_pull_requests(status, branch=nil)
        extra_params = {}
        extra_params[:head] = "#{repo_user}:#{branch}" if branch
        prs = GitHub.pull_requests(repo, status, extra_params)
        puts "No pull requests found." if prs.empty?
        prs.each do |pr|
          print_pr(pr)
        end
      end

      def print_pr(pr, short_str=nil)
        if options[:verbose] || short_str.nil?
          puts verbose_pr_str(pr)
        else
          puts short_str
        end
      end

      def verbose_pr_str(pr)
        "#{pr['number']} \"#{pr['title']}\" [#{pr['head']['ref']}@#{pr['head']['sha'][0..6]}] #{pr['user']['login']}"
      end

      def is_int?(str)
        /\A\d+\z/.match(str)
      end

      def repo_user
        repo.split('/').first
      end

    end
  end
end
