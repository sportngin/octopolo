require "spec_helper"
require_relative "../../lib/octopolo/user_config"

module Octopolo
  describe UserConfig do
    context ".parse" do
      let(:parsed_attributes) { {foo: "bar"} }
      let(:config) { double(:user_config) }

      it "reads from the user's config file and instantiates a new user config instance" do
        UserConfig.should_receive(:attributes_from_file) { parsed_attributes }
        UserConfig.should_receive(:new).with(parsed_attributes) { config }

        UserConfig.parse.should eq(config)
      end
    end

    context ".new attributes" do
      let(:attributes) { {github_user: "joeuser"} }

      it "remembers the attributes given to it" do
        config = UserConfig.new(attributes)
        config.attributes.should eq(attributes)
        config.github_user.should eq(attributes[:github_user])
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
        UserConfig.attributes_from_file.should eq(YAML.load_file(path))
      end

      it "creates the file if it doesn't exist" do
        YAML.should_receive(:load_file).and_raise(Errno::ENOENT)
        UserConfig.should_receive(:touch_config_file)
        UserConfig.attributes_from_file.should eq({})
      end
    end

    context ".config_path" do
      it "is ~/.octopolo/config.yml" do
        UserConfig.config_path.should eq(File.join(UserConfig.config_parent, "config.yml"))
      end
    end

    context ".config_parent" do
      it "defaults to ~/.octopolo" do
        allow(Dir).to receive(:exist?).and_return(true)
        UserConfig.config_parent.should eq(File.expand_path("~/.octopolo"))
      end

      it "returns ~/.automation if ~/.octopolo does not exist" do
        allow(Dir).to receive(:exist?).and_return(false)
        UserConfig.config_parent.should eq(File.expand_path("~/.automation"))
      end
    end

    context ".touch_config_file" do
      before do
        allow(UserConfig).to receive(:config_parent) { File.expand_path("~/.octopolo") }
      end

      it "should properly handle if ~/.octopolo doesn't exist" do
        allow(Dir).to receive(:exist?).with(UserConfig.config_parent) { false }
        allow(Dir).to receive(:mkdir).with(UserConfig.config_parent)
        allow(File).to receive(:exist?).with(UserConfig.config_path) { false }
        allow(File).to receive(:write).with(UserConfig.config_path, YAML.dump({}))
        UserConfig.touch_config_file
      end

      it "writes an empty hash if ~/.octopolo exists but the config doesn't" do
        allow(Dir).to receive(:exist?).with(UserConfig.config_parent) { true }
        expect(Dir).to_not receive(:mkdir)
        allow(File).to receive(:exist?).with(UserConfig.config_path) { false }
        allow(File).to receive(:write).with(UserConfig.config_path, YAML.dump({}))
        UserConfig.touch_config_file
      end

      it "does nothing if the file already exists" do
        allow(Dir).to receive(:exist?).with(UserConfig.config_parent) { true }
        expect(Dir).to_not receive(:mkdir)
        allow(File).to receive(:exist?).with(UserConfig.config_path) { true }
        expect(File).to_not receive(:write)
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
        config.full_name.should eq(new_value)
      end
    end

    context "#full_name" do
      let(:config) { UserConfig.new }
      let(:name) { "Joe Person" }

      it "returns the configured full_name" do
        config.full_name = name
        config.full_name.should eq(name)
      end

      it "returns the user's system username otherwise" do
        config.full_name = nil
        config.full_name.should eq(ENV["USER"])
      end
    end

    context "#editor" do
      let(:config) { UserConfig.new }

      it "returns the configured value" do
        config.editor = true
        config.editor.should eq(true)
      end

      it "returns false otherwise" do
        config.editor.should eq(false)
      end
    end

    context "#github_user" do
      let(:config) { UserConfig.new }
      let(:username) { "joeperson" }

      it "returns the configured github_user" do
        config.github_user = username
        config.github_user.should eq(username)
      end

      it "raises MissingGitHubAuth if missing" do
        config.github_user = nil
        expect { config.github_user }.to raise_error(UserConfig::MissingGitHubAuth)
      end
    end

    context "#github_token" do
      let(:config) { UserConfig.new }
      let(:token) { double(:string) }

      it "returns the configured github_token" do
        config.github_token = token
        config.github_token.should eq(token)
      end

      it "raises MissingGitHubAuth if missing" do
        config.github_token = nil
        expect { config.github_token }.to raise_error(UserConfig::MissingGitHubAuth)
      end
    end
  end
end
