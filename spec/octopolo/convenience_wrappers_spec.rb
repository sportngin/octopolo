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
    let(:cli) { stub_const('CLI', class_double(CLI)) }

    context "#cli" do
      it "wraps around the CLI class" do
        foo.cli.should == CLI
      end

      it "uses the given CLI class" do
        foo.cli = cli
        foo.cli.should == cli
      end
    end
  end

  describe ConfigWrapper do
    let(:foo) { Foo.new }
    let(:config) { double(:config) }

    context "#config" do
      it "parses the current config" do
        Octopolo.should_receive(:config) { config }
        foo.config.should == config
      end

      it "uses the given parsed config" do
        Config.should_not_receive(:parse)
        foo.config = config
        foo.config.should == config
      end
    end
  end

  describe UserConfigWrapper do
    let(:foo) { Foo.new }
    let(:user_config) { double(:user_config) }

    context "#user_config" do
      it "parses the current user config" do
        UserConfig.should_receive(:parse) { user_config }
        foo.user_config.should == user_config
      end

      it "uses the given parsed config" do
        foo.user_config = user_config
        UserConfig.should_not_receive(:parse)
        foo.user_config.should == user_config
      end
    end
  end

  describe GitWrapper do
    subject { Foo.new }
    let(:git) { stub_const('Git', class_double(Git)) }

    context "#git" do
      it "wraps around the Git class" do
        subject.git.should == Git
      end

      it "uses the given Git" do
        subject.git = git
        subject.git.should == git
      end
    end
  end
end
