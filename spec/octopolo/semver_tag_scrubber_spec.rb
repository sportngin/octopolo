require "spec_helper"
require "octopolo/semver_tag_scrubber"

module Octopolo
  describe SemverTagScrubber do
    let(:tag) { "Prefix0.0.1Suffix" }

    describe "::scrub_prefix" do
      it "returns the prefix" do
        expect(SemverTagScrubber.scrub_prefix tag).to eq("Prefix")
      end

      it "scrub the prefix from the tag" do
        SemverTagScrubber.scrub_prefix tag
        expect(tag).to eq("0.0.1Suffix")
      end
    end

    describe "::scrub_suffix" do
      it "returns the suffix" do
        expect(SemverTagScrubber.scrub_suffix tag).to eq("Suffix")
      end

      it "scrub the suffix from the tag" do
        SemverTagScrubber.scrub_suffix tag
        expect(tag).to eq("Prefix0.0.1")
      end
    end

  end
end
