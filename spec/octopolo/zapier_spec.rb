require "spec_helper"
require "octopolo/zapier"

module Octopolo
  describe Zapier do
    context ".endpoint ID" do
      it "returns the endpoint URL for the given Zap ID" do
        Zapier.endpoint(123).should == "https://zapier.com/hooks/WebHookAPI/?sid=123"
      end
    end

    context ".encode pull_request" do
      let(:pull_request) { stub(:pull_request) }
      let(:cs_encoder) { stub(:pull_request_encoder) }
      let(:devo_encoder) { stub(:pull_request_encoder) }
      let(:prod_encoder) { stub(:pull_request_encoder) }

      context "when pull request is a bug" do
        before { pull_request.stub(bug?: true) }

        it "wraps around the pull request encoder" do
          Zapier::PullRequestEncoder.should_receive(:new).with(pull_request, "client-services-bugs") { cs_encoder }
          Zapier::PullRequestEncoder.should_receive(:new).with(pull_request, "devo-all") { devo_encoder }
          Zapier::PullRequestEncoder.should_receive(:new).with(pull_request, "product-all") { prod_encoder }
          cs_encoder.should_receive(:perform)
          devo_encoder.should_receive(:perform)
          prod_encoder.should_receive(:perform)
          Zapier.encode pull_request
        end
      end

      context "when pull request is not a bug" do
        before { pull_request.stub(bug?: false) }

        it "wraps around the pull request encoder" do
          Zapier::PullRequestEncoder.should_not_receive(:new).with(pull_request, "client-services-bugs")
          Zapier::PullRequestEncoder.should_receive(:new).with(pull_request, "devo-all") { devo_encoder }
          Zapier::PullRequestEncoder.should_receive(:new).with(pull_request, "product-all") { prod_encoder }
          cs_encoder.should_not_receive(:perform)
          devo_encoder.should_receive(:perform)
          prod_encoder.should_receive(:perform)
          Zapier.encode pull_request
        end
      end
    end

    context ".post_deploy_notes" do
      let(:cs_poster) { stub(:pull_request_poster) }
      let(:devo_poster) { stub(:pull_request_poster) }
      let(:prod_poster) { stub(:pull_request_poster) }

      it "wraps around the pull request poster" do
        Zapier::PullRequestPoster.should_receive(:new).with("client-services-bugs", [Zapier::PR_TO_CS_CAMPFIRE]) { cs_poster }
        Zapier::PullRequestPoster.should_receive(:new).with("devo-all", [Zapier::PR_TO_DEVO_CAMPFIRE]) { devo_poster }
        Zapier::PullRequestPoster.should_receive(:new).with("product-all", [Zapier::PR_TO_PRODUCT_TRELLO]) { prod_poster }
        cs_poster.should_receive(:perform)
        devo_poster.should_receive(:perform)
        prod_poster.should_receive(:perform)
        Zapier.post_deploy_notes
      end
    end
  end
end
