require "spec_helper"
require "automation/convenience_wrappers"
require "automation/git"

module Automation
  class Foo
    include CLIWrapper
    include ConfigWrapper
    include UserConfigWrapper
    include EngineYardAPIWrapper
    include GitWrapper
  end

  describe CLIWrapper do
    let(:foo) { Foo.new }
    let(:cli) { stub(:CLI) }

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
    let(:config) { stub(:config) }

    context "#config" do
      it "parses the current config" do
        Config.should_receive(:parse) { config }
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
    let(:user_config) { stub(:user_config) }

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

  describe EngineYardAPIWrapper do
    let(:foo) { Foo.new }
    let(:engine_yard) { stub(:engine_yard_api) }

    context "#engine_yard" do
      it "instantiates the Engine Yard API wrapper" do
        EngineYardAPI.should_receive(:new) { engine_yard }
        foo.engine_yard.should == engine_yard
      end

      it "uses the given wrapper" do
        EngineYardAPI.should_not_receive(:new)
        foo.engine_yard = engine_yard
        foo.engine_yard.should == engine_yard
      end
    end
  end

  describe GitWrapper do
    subject { Foo.new }
    let(:git) { stub(:Git) }

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
