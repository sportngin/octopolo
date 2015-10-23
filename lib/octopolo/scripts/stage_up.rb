require_relative "../scripts"
require_relative "../pull_request_merger"
require_relative "../validator"

module Octopolo
  module Scripts
    class StageUp
      include CLIWrapper

      attr_accessor :pull_request_id

      def self.execute(pull_request_id=nil, options={})
        new(pull_request_id, options).execute(options[:skip_validations])
      end

      def initialize(pull_request_id=nil, options={})
        @pull_request_id = pull_request_id
      end

      # Public: Perform the script
      def execute(skip_validations=false)
        Validator.new.is_valid? unless skip_validations
        self.pull_request_id ||= cli.prompt("Pull Request ID: ")
        PullRequestMerger.perform Git::STAGING_PREFIX, Integer(pull_request_id)
      end
    end
  end
end
