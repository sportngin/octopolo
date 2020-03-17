require "spec_helper"
require_relative "../../lib/octopolo/convenience_wrappers"
require_relative "../../lib/octopolo/git"

module Octopolo
  class Foo
    include CLIWrapper
    include ConfigWrapper
    include UserConfigWrapper
    include GitWrapper
  end

  describe CLIWrapper do
    let(:foo) { Foo.new }
    let(:cli) { double(:CLI) }

    context "#cli" do
      it "wraps around the CLI class" do
        expect(foo.cli).to eq(CLI)
      end

      it "uses the given CLI class" do
        foo.cli = cli
        expect(foo.cli).to eq(cli)
      end
    end
  end

  describe ConfigWrapper do
    let(:foo) { Foo.new }
    let(:config) { double(:config) }

    context "#config" do
      it "parses the current config" do
        expect(Octopolo).to receive(:config) { config }
        expect(foo.config).to eq(config)
      end

      it "uses the given parsed config" do
        expect(Config).not_to receive(:parse)
        foo.config = config
        expect(foo.config).to eq(config)
      end
    end
  end

  describe UserConfigWrapper do
    let(:foo) { Foo.new }
    let(:user_config) { double(:user_config) }

    context "#user_config" do
      it "parses the current user config" do
        expect(UserConfig).to receive(:parse) { user_config }
        expect(foo.user_config).to eq(user_config)
      end

      it "uses the given parsed config" do
        foo.user_config = user_config
        expect(UserConfig).not_to receive(:parse)
        expect(foo.user_config).to eq(user_config)
      end
    end
  end

  describe GitWrapper do
    subject { Foo.new }
    let(:git) { double(:Git) }

    context "#git" do
      it "wraps around the Git class" do
        expect(subject.git).to eq(Git)
      end

      it "uses the given Git" do
        subject.git = git
        expect(subject.git).to eq(git)
      end
    end
  end
end
