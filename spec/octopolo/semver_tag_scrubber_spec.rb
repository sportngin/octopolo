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

    describe 'scrub_via_regexp' do
      let(:regexp) { /[a-z]*\z/i }
      let(:tag) { '0.1.1' }

      it 'should return a string' do
        expect(SemverTagScrubber.scrub_via_regexp(tag, regexp)).to be_a(String)
      end

      it 'should not raise an error if the tag does not exist' do
        expect{ SemverTagScrubber.scrub_via_regexp(nil, regexp) }.not_to raise_error(NoMethodError)
      end

      it 'should return nil if there was no tag' do
        expect(SemverTagScrubber.scrub_via_regexp(nil, regexp)).to eq(nil)
      end
    end
  end
end
