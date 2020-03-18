require "spec_helper"
require "fileutils"

module Octopolo
  describe Config do
    let(:cli) { double("cli") }

    context "#initialize" do
      subject { Config }

      it "loads plugins" do
        expect_any_instance_of(subject).to receive(:load_plugins)
        subject.new(deploy_branch: "foo", branches_to_keep: ["a", "b"])
      end

      it "sets up methods for all the attributes it receives" do
        config = subject.new(deploy_branch: "foo", branches_to_keep: ["a", "b"])

        expect(config.deploy_branch).to eq("foo")
        expect(config.branches_to_keep).to eq(["a", "b"])
      end
    end

    context "default cuzomizable methods" do
      context "#deploy_branch" do
        it "is master by default" do
          expect(Config.new.deploy_branch).to eq("master")
        end

        it "is the specified branch otherwise" do
          expect(Config.new(deploy_branch: "production").deploy_branch).to eq("production")
        end
      end

      context "#branches_to_keep" do
        it "is an empty array by default" do
          expect(Config.new.branches_to_keep).to eq([])
        end

        it "is the specified values otherwise" do
          expect(Config.new(branches_to_keep: ["a", "b"]).branches_to_keep).to eq(["a", "b"])
        end
      end

      context "#deploy_methods" do
        it "is an empty array by default" do
          expect(Config.new.deploy_methods).to eq([])
        end

        it "is the specified values otherwise" do
          expect(Config.new(deploy_methods: ["a", "b"]).deploy_methods).to eq(["a", "b"])
        end
      end

      context "#deploy_environments" do
        it "is an empty array by default" do
          expect(Config.new.deploy_environments).to eq([])
        end

        it "is the specified values otherwise" do
          expect(Config.new(deploy_environments: ["a", "b"]).deploy_environments).to eq(["a", "b"])
        end
      end

      context "#deployable_label" do 
        it "is true by default" do
          expect(Config.new.deployable_label).to eq(true)
        end

        it "is can be configured as well" do
          expect(Config.new(deployable_label: false).deployable_label).to eq(false)
        end
      end

      context "#github_repo" do
        it "raises an exception if not given" do
          expect { Config.new.github_repo }.to raise_error(Config::MissingRequiredAttribute)
        end

        it "returns the specified value otherwise" do
          expect(Config.new(github_repo: "tstmedia/ngin").github_repo).to eq("tstmedia/ngin")
        end
      end

      context "#merge_resolver" do
        it "is nil by default" do
          expect(Config.new.merge_resolver).to eq(nil)
        end

        it "returns a string if it has a value" do
          expect(Config.new(merge_resolver: "/opt/resolver.sh").merge_resolver).to eq("/opt/resolver.sh")
        end
      end

      context "#user_notifications" do
        it "is nil by default" do
          expect(Config.new.user_notifications).to eq(nil)
        end

        it "raise an error if it is not an array" do
          expect { Config.new(user_notifications: {:user => "NickLaMuro"}).user_notifications }.to raise_error(Config::InvalidAttributeSupplied)
        end

        it "returns the specified value if an array" do
          expect(Config.new(user_notifications: ["NickLaMuro"]).user_notifications).to eq(["NickLaMuro"])
        end

        it "returns the specified value if as an array if a string" do
          expect(Config.new(user_notifications: "NickLaMuro").user_notifications).to eq(["NickLaMuro"])
        end
      end

      context "#plugins" do
        before { allow_any_instance_of(Config).to receive(:load_plugins) }

        it "defaults to an empty array" do
          expect(Config.new.plugins).to eq([])
        end

        it "raise an error if it is not a string or array" do
          expect { Config.new(plugins: {:user => "foo-plugin"}).plugins }.to raise_error(Config::InvalidAttributeSupplied)
        end

        it "returns the specified single plugin as an array" do
          expect(Config.new(plugins: "octopolo-templates").plugins).to eq(["octopolo-templates"])
        end

        it "returns the specified plugins as an array" do
          expect(Config.new(plugins: ["op-templates"]).plugins).to eq(["op-templates"])
        end
      end

      context "#use_jira" do
        it "defaults to false" do
          expect(Config.new.use_jira).to be_falsey
        end

        it "forces a truthy value to be true" do
          expect(Config.new(use_jira: "true").use_jira).to be_truthy
        end
      end

      context "#jira_user" do
        it "does not raise an exception if jira isn't enabled" do
          expect { Config.new.jira_user }.to_not raise_error
        end

        it "raises an exception if not given" do
          expect { Config.new(use_jira: true).jira_user }.to raise_error(Config::MissingRequiredAttribute)
        end

        it "returns the specified value otherwise" do
          expect(Config.new(use_jira: true, jira_user: "jira-user").jira_user).to eq("jira-user")
        end
      end

      context "#jira_password" do
        it "does not raise an exception if jira isn't enabled" do
          expect { Config.new.jira_password }.to_not raise_error
        end

        it "raises an exception if not given" do
          expect { Config.new(use_jira: true).jira_password }.to raise_error(Config::MissingRequiredAttribute)
        end

        it "returns the specified value otherwise" do
          expect(Config.new(use_jira: true, jira_password: "jira-password").jira_password).to eq("jira-password")
        end
      end
      context "#jira_url" do
        it "does not raise an exception if jira isn't enabled" do
          expect { Config.new.jira_url }.to_not raise_error
        end

        it "raises an exception if not given" do
          expect { Config.new(use_jira: true).jira_url }.to raise_error(Config::MissingRequiredAttribute)
        end

        it "returns the specified value otherwise" do
          expect(Config.new(use_jira: true, jira_url: "jira-url").jira_url).to eq("jira-url")
        end
      end
    end

    context "loading in plugins" do
      context "in a seperate state" do
        fork {
          before { Config.new(:plugins => "octopolo_plugin_example") }

          it "include the plugin in the object space" do
            expect{ ExamplePlugin.new.example_method }.not_to raise_error
          end

          it "includes any monkey patching" do
            expect(subject.example_var).to eq(ExamplePlugin::EXAMPLE_CONSTANT)
          end
        }
      end

      context "in a clean state" do
        it "not include the plugin in the object space" do
          expect{ ExamplePlugin.new.example_method }.to raise_error NameError
        end

        it "not include any monkey patching" do
          expect{ expect(subject.example_var).to }.to raise_error NoMethodError
        end
      end
    end

    context ".parse" do
      let(:parsed_attributes) { { :foo => "bar" }}
      subject { Config }

      it "reads from the .octopolo.yml file and creates a new config instance" do
        expect(subject).to receive(:attributes_from_file).and_return(parsed_attributes)
        expect(subject).to receive(:new).with(parsed_attributes)

        subject.parse
      end
    end

    context ".attributes_from_file" do
      let(:stub_path) { File.join(Dir.pwd, 'spec', 'support', 'sample_octopolo.yml') }
      subject { Config }

      it "parses the YAML in the octopolo_config_path" do
        allow(subject).to receive(:octopolo_config_path).and_return(stub_path)
        expect(subject.attributes_from_file).to eq(YAML.load_file(stub_path))
      end
    end

    context ".octopolo_config_path" do
      let(:project_working_dir) { Dir.pwd }
      subject { Config }
      before { project_working_dir }

      it "gives up if it can't find a config file" do
        allow(File).to receive(:exists?) { false }
        expect(Octopolo::CLI).to receive(:say).with("*** WARNING: Could not find .octopolo.yml or .automation.yml ***")
        subject.octopolo_config_path
        Dir.chdir project_working_dir
      end

      context "with a .octopolo.yml file" do
        before do
          FileUtils.cp "spec/support/sample_octopolo.yml", "spec/support/.octopolo.yml"
        end

        it "is the .octopolo.yml file in the project directory" do
          Dir.chdir "spec/support"
          expect(subject.octopolo_config_path).to eq(File.join(Dir.pwd, '.octopolo.yml'))
        end

        it "is the .octopolo.yml file in the project directory, two directories up" do
          FileUtils.mkdir_p "spec/support/tmp/foo"
          Dir.chdir "spec/support/tmp/foo"
          expect(subject.octopolo_config_path).to eq(File.join(Dir.pwd, '.octopolo.yml'))
        end

        after do
          Dir.chdir project_working_dir
          FileUtils.rm "spec/support/.octopolo.yml"
          FileUtils.rm_f "spec/support/tmp"
        end
      end

      context "with a .automation.yml file" do
        before do
          FileUtils.cp "spec/support/sample_octopolo.yml", "spec/support/.automation.yml"
        end

        it "is the .octopolo.yml file in the project directory" do
          Dir.chdir "spec/support"
          expect(subject.octopolo_config_path).to eq(File.join(Dir.pwd, '.automation.yml'))
        end

        it "is the .octopolo.yml file in the project directory, two directories up" do
          FileUtils.mkdir_p "spec/support/tmp/foo"
          Dir.chdir "spec/support/tmp/foo"
          expect(subject.octopolo_config_path).to eq(File.join(Dir.pwd, '.automation.yml'))
        end

        after do
          Dir.chdir project_working_dir
          FileUtils.rm "spec/support/.automation.yml"
          FileUtils.rm_f "spec/support/tmp"
        end
      end

    end

    context "#load_plugins" do
      context "with valid plugins" do
        subject { Config.new(:plugins => "rspec") }

        it "loads the plugins" do
          subject.load_plugins
        end
      end

      context "with invalid plugins" do
        subject { Config.new }

        it "skips loading the plugin and displays a message" do
          subject.instance_variable_set(:@plugins, "not-a-real-plugin")
          expect(subject).to receive(:puts)
                 .with("Plugin 'not-a-real-plugin' failed to load")

          subject.load_plugins
        end
      end
    end

    context "#remote_branch_exists?" do
      before do
        allow(Octopolo::CLI).to receive_messages(:perform => <<-BR
                          * origin/production
                            origin/test
                            origin/asdf
                            BR
                            )
      end

      it "should find production" do
        expect(subject.remote_branch_exists?("production")).to eq(true)
      end

      it "shouldn't production" do
        expect(subject.remote_branch_exists?("not-there")).to eq(false)
      end
    end

    context "#basedir" do
      let(:project_working_dir) { Dir.pwd }
      before do
        project_working_dir
        FileUtils.cp "spec/support/sample_octopolo.yml", "spec/support/.octopolo.yml"
      end

      it "returns the name of the directory containing the .octopolo.yml file" do
        Dir.chdir "spec/support"
        config = Config.new
        expected_value = File.basename(File.dirname(Config.octopolo_config_path))
        expect(config.basedir).to eq(expected_value)
      end

      after do
        Dir.chdir project_working_dir
        FileUtils.rm "spec/support/.octopolo.yml"
      end
    end
  end
end
