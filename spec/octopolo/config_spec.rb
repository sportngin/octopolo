require "spec_helper"
require "fileutils"

module Octopolo
  describe Config do
    let(:cli) { mock("cli") }

    context "#initialize" do
      subject { Config }

      it "loads plugins" do
        subject.any_instance.should_receive(:load_plugins)
        subject.new(deploy_branch: "foo", branches_to_keep: ["a", "b"])
      end

      it "sets up methods for all the attributes it receives" do
        config = subject.new(deploy_branch: "foo", branches_to_keep: ["a", "b"])

        config.deploy_branch.should == "foo"
        config.branches_to_keep.should == ["a", "b"]
      end
    end

    context "default cuzomizable methods" do
      context "#deploy_branch" do
        it "is master by default" do
          Config.new.deploy_branch.should == "master"
        end

        it "is the specified branch otherwise" do
          Config.new(deploy_branch: "production").deploy_branch.should == "production"
        end
      end

      context "#branches_to_keep" do
        it "is an empty array by default" do
          Config.new.branches_to_keep.should == []
        end

        it "is the specified values otherwise" do
          Config.new(branches_to_keep: ["a", "b"]).branches_to_keep.should == ["a", "b"]
        end
      end

      context "#deploy_methods" do
        it "is an empty array by default" do
          Config.new.deploy_methods.should == []
        end

        it "is the specified values otherwise" do
          Config.new(deploy_methods: ["a", "b"]).deploy_methods.should == ["a", "b"]
        end
      end

      context "#deploy_environments" do
        it "is an empty array by default" do
          Config.new.deploy_environments.should == []
        end

        it "is the specified values otherwise" do
          Config.new(deploy_environments: ["a", "b"]).deploy_environments.should == ["a", "b"]
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
        it "finds repo when not given" do
          Config.any_instance.github_repo.stub(:find_repo) { 'foo/ngin-bar' }
        end

        it "returns the specified value otherwise" do
          Config.new(github_repo: "tstmedia/ngin").github_repo.should == "tstmedia/ngin"
        end
      end

      context "#merge_resolver" do
        it "is nil by default" do
          Config.new.merge_resolver.should == nil
        end

        it "returns a string if it has a value" do
          Config.new(merge_resolver: "/opt/resolver.sh").merge_resolver.should == "/opt/resolver.sh"
        end
      end

      context "#user_notifications" do
        it "is nil by default" do
          Config.new.user_notifications.should == nil
        end

        it "raise an error if it is not an array" do
          expect { Config.new(user_notifications: {:user => "NickLaMuro"}).user_notifications }.to raise_error(Config::InvalidAttributeSupplied)
        end

        it "returns the specified value if an array" do
          Config.new(user_notifications: ["NickLaMuro"]).user_notifications.should == ["NickLaMuro"]
        end

        it "returns the specified value if as an array if a string" do
          Config.new(user_notifications: "NickLaMuro").user_notifications.should == ["NickLaMuro"]
        end
      end

      context "#plugins" do
        before { Config.any_instance.stub(:load_plugins) }

        it "defaults to an empty array" do
          Config.new.plugins.should == []
        end

        it "raise an error if it is not a string or array" do
          expect { Config.new(plugins: {:user => "foo-plugin"}).plugins }.to raise_error(Config::InvalidAttributeSupplied)
        end

        it "returns the specified single plugin as an array" do
          Config.new(plugins: "octopolo-templates").plugins.should == ["octopolo-templates"]
        end

        it "returns the specified plugins as an array" do
          Config.new(plugins: ["op-templates", "op-pivotal"]).plugins.should == ["op-templates", "op-pivotal"]
        end
      end

      context "#use_pivotal_tracker" do
        it "defaults to false" do
          expect(Config.new.use_pivotal_tracker).to be_false
        end

        it "forces a truthy value to be true" do
          expect(Config.new(use_pivotal_tracker: "true").use_pivotal_tracker).to be_true
        end
      end

      context "#use_jira" do
        it "defaults to false" do
          expect(Config.new.use_jira).to be_false
        end

        it "forces a truthy value to be true" do
          expect(Config.new(use_jira: "true").use_jira).to be_true
        end
      end

      context "#jira_user" do
        it "does not raise an exception if jira isn't enabled" do
          expect { Config.new.jira_user }.to_not raise_error(Config::MissingRequiredAttribute)
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
          expect { Config.new.jira_password }.to_not raise_error(Config::MissingRequiredAttribute)
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
          expect { Config.new.jira_url }.to_not raise_error(Config::MissingRequiredAttribute)
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
            subject.example_var.should == ExamplePlugin::EXAMPLE_CONSTANT
          end
        }
      end

      context "in a clean state" do
        it "not include the plugin in the object space" do
          expect{ ExamplePlugin.new.example_method }.to raise_error NameError
        end

        it "not include any monkey patching" do
          expect{ subject.example_var.should }.to raise_error NoMethodError
        end
      end
    end

    context ".parse" do
      let(:parsed_attributes) { { :foo => "bar" }}
      subject { Config }

      it "reads from the .octopolo.yml file and creates a new config instance" do
        subject.should_receive(:attributes_from_file).and_return(parsed_attributes)
        subject.should_receive(:new).with(parsed_attributes)

        subject.parse
      end
    end

    context ".attributes_from_file" do
      let(:stub_path) { File.join(Dir.pwd, 'spec', 'support', 'sample_octopolo.yml') }
      subject { Config }

      it "parses the YAML in the octopolo_config_path" do
        subject.stub(:octopolo_config_path).and_return(stub_path)
        subject.attributes_from_file.should == YAML.load_file(stub_path)
      end
    end

    context ".octopolo_config_path" do
      let(:project_working_dir) { Dir.pwd }
      subject { Config }
      before { project_working_dir }

      context "with a .octopolo.yml file" do
        before do
          FileUtils.cp "spec/support/sample_octopolo.yml", "spec/support/.octopolo.yml"
        end

        it "is the .octopolo.yml file in the project directory" do
          Dir.chdir "spec/support"
          subject.octopolo_config_path.should == File.join(Dir.pwd, '.octopolo.yml')
        end

        it "is the .octopolo.yml file in the project directory, two directories up" do
          FileUtils.mkdir_p "spec/support/tmp/foo"
          Dir.chdir "spec/support/tmp/foo"
          subject.octopolo_config_path.should == File.join(Dir.pwd, '.octopolo.yml')
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
          subject.octopolo_config_path.should == File.join(Dir.pwd, '.automation.yml')
        end

        it "is the .octopolo.yml file in the project directory, two directories up" do
          FileUtils.mkdir_p "spec/support/tmp/foo"
          Dir.chdir "spec/support/tmp/foo"
          subject.octopolo_config_path.should == File.join(Dir.pwd, '.automation.yml')
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
          subject.should_receive(:puts)
                 .with("Plugin 'not-a-real-plugin' failed to load")

          subject.load_plugins
        end
      end
    end

    context "#remote_branch_exists?" do
      before do
        Octopolo::CLI.stub(:perform => <<-BR
                          * origin/production
                            origin/test
                            origin/asdf
                            BR
                            )
      end

      it "should find production" do
        subject.remote_branch_exists?("production").should == true
      end

      it "shouldn't production" do
        subject.remote_branch_exists?("not-there").should == false
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
        config.basedir.should == expected_value
      end

      after do
        Dir.chdir project_working_dir
        FileUtils.rm "spec/support/.octopolo.yml"
      end
    end
  end
end
