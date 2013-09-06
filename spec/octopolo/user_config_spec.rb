require "spec_helper"
require "octopolo/user_config"

module Octopolo
  describe UserConfig do
    context ".parse" do
      let(:parsed_attributes) { {foo: "bar"} }
      let(:config) { stub(:user_config) }

      it "reads from the user's config file and instantiates a new user config instance" do
        UserConfig.should_receive(:attributes_from_file) { parsed_attributes }
        UserConfig.should_receive(:new).with(parsed_attributes) { config }

        UserConfig.parse.should == config
      end
    end

    context ".new attributes" do
      let(:attributes) { {github_user: "joeuser"} }

      it "remembers the attributes given to it" do
        config = UserConfig.new(attributes)
        config.attributes.should == attributes
        config.github_user.should == attributes[:github_user]
      end

      it "gracefully handles unknown keys" do
        expect { UserConfig.new(foo: "bar") }.to_not raise_error
      end
    end

    context ".attributes_from_file" do
      let(:path) { File.join(Dir.pwd, "spec", "support", "sample_user.yml") }

      before do
        UserConfig.stub(:config_path) { path }
      end

      it "parses the YAML in the config_path" do
        UserConfig.attributes_from_file.should == YAML.load_file(path)
      end

      it "creates the file if it doesn't exist" do
        YAML.should_receive(:load_file).and_raise(Errno::ENOENT)
        UserConfig.should_receive(:touch_config_file)
        UserConfig.attributes_from_file.should == {}
      end
    end

    context ".config_path" do
      it "is ~/.octopolo/config.yml" do
        UserConfig.config_path.should == File.join(UserConfig.config_parent, "config.yml")
      end
    end

    context ".config_parent" do
      it "is ~/.octopolo" do
        UserConfig.config_parent.should == File.expand_path("~/.octopolo")
      end
    end

    context ".touch_config_file" do
      it "should properly handle if ~/.octopolo doesn't exist" do
        Dir.should_receive(:exist?).with(UserConfig.config_parent) { false }
        Dir.should_receive(:mkdir).with(UserConfig.config_parent)
        File.should_receive(:exist?).with(UserConfig.config_path) { false }
        File.should_receive(:write).with(UserConfig.config_path, YAML.dump({}))
        UserConfig.touch_config_file
      end

      it "writes an empty hash if ~/.octopolo exists but the config doesn't" do
        Dir.should_receive(:exist?).with(UserConfig.config_parent) { true }
        Dir.should_not_receive(:mkdir)
        File.should_receive(:exist?).with(UserConfig.config_path) { false }
        File.should_receive(:write).with(UserConfig.config_path, YAML.dump({}))
        UserConfig.touch_config_file
      end

      it "does nothing if the file already exists" do
        Dir.should_receive(:exist?).with(UserConfig.config_parent) { true }
        Dir.should_not_receive(:mkdir)
        File.should_receive(:exist?).with(UserConfig.config_path) { true }
        File.should_not_receive(:write)
        UserConfig.touch_config_file
      end
    end

    context "#set key, value" do
      let(:path) { File.join(Dir.pwd, "spec", "support", "sample_user.yml") }
      let(:config) { UserConfig.new(YAML.load_file(path)) }
      let(:new_value) { "My Name" }

      it "updates the YAML and its own values" do
        config.full_name.should_not == new_value
        File.should_receive(:write).with(UserConfig.config_path, YAML.dump(config.attributes.merge(full_name: new_value)))
        config.set(:full_name, "My Name")
        config.full_name.should == new_value
      end
    end

    context "#full_name" do
      let(:config) { UserConfig.new }
      let(:name) { "Joe Person" }

      it "returns the configured full_name" do
        config.full_name = name
        config.full_name.should == name
      end

      it "returns the user's system username otherwise" do
        config.full_name = nil
        config.full_name.should == ENV["USER"]
      end
    end

    context "#github_user" do
      let(:config) { UserConfig.new }
      let(:username) { "joeperson" }

      it "returns the configured github_user" do
        config.github_user = username
        config.github_user.should == username
      end

      it "raises MissingGitHubAuth if missing" do
        config.github_user = nil
        expect { config.github_user }.to raise_error(UserConfig::MissingGitHubAuth)
      end
    end

    context "#github_token" do
      let(:config) { UserConfig.new }
      let(:token) { stub(:string) }

      it "returns the configured github_token" do
        config.github_token = token
        config.github_token.should == token
      end

      it "raises MissingGitHubAuth if missing" do
        config.github_token = nil
        expect { config.github_token }.to raise_error(UserConfig::MissingGitHubAuth)
      end
    end

    context "#pivotal_token" do
      let(:config) { UserConfig.new }
      let(:token) { "token" }

      it "returns the configured Pivotal Tracker token" do
        config.pivotal_token = token
        config.pivotal_token.should == token
      end

      it "raises MissingPivotalAuth if missing" do
        config.pivotal_token = nil
        expect { config.pivotal_token }.to raise_error(UserConfig::MissingPivotalAuth)
      end
    end
  end
end
