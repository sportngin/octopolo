require "automation/zapier/pull_request_encoder"
require "automation/zapier/pull_request_poster"
require "automation/zapier/branch_poster"
require "automation/zapier/deploy_poster"

module Automation
  module Zapier
    # Zap IDs
    MESSAGE_TO_DEVO = 42757
    PR_TO_DEVO_CAMPFIRE = 27600
    PR_TO_CS_CAMPFIRE = 27536
    PR_TO_CHATTER = 27586
    PR_TO_PRODUCT_TRELLO = 179542

    # edit: https://zapier.com/app/edit/ZAP_ID
    # endpoint: https://zapier.com/hooks/WebHookAPI/?sid=ZAP_ID
    def self.endpoint(zap_id)
      "https://zapier.com/hooks/WebHookAPI/?sid=#{zap_id}"
    end

    # Public: Encode the given pull request for Zapier notifications
    def self.encode(pull_request)
      PullRequestEncoder.new(pull_request, "client-services-bugs").perform if pull_request.bug?
      PullRequestEncoder.new(pull_request, "devo-all").perform
      PullRequestEncoder.new(pull_request, "product-all").perform
    end

    # Public: Post deploy notes for the accepted pull requests
    def self.post_deploy_notes
      PullRequestPoster.new("client-services-bugs", [PR_TO_CS_CAMPFIRE]).perform
      PullRequestPoster.new("devo-all", [PR_TO_DEVO_CAMPFIRE]).perform
      PullRequestPoster.new("product-all", [PR_TO_PRODUCT_TRELLO]).perform
    end
  end
end
