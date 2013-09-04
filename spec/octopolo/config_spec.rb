require "spec_helper"

module Automation
  describe Config do
    let(:cache_path) { File.expand_path("../../support/engine_yard.cache", __FILE__) }
    let(:cli) { mock("cli") }

    context "#initialize" do
      subject { Config }

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

      context "#github_repo" do
        it "raises an exception if not given" do
          expect { Config.new.github_repo }.to raise_error(Config::MissingRequiredAttribute)
        end

        it "returns the specified value otherwise" do
          Config.new(github_repo: "tstmedia/ngin").github_repo.should == "tstmedia/ngin"
        end
      end
    end

    context ".parse" do
      let(:parsed_attributes) { { :foo => "bar" }}
      subject { Config }

      it "reads from the .automation.yml file and creates a new config instance" do
        subject.should_receive(:attributes_from_file).and_return(parsed_attributes)
        subject.should_receive(:new).with(parsed_attributes)

        subject.parse
      end
    end

    context ".attributes_from_file" do
      let(:stub_path) { File.join(Dir.pwd, 'spec', 'support', 'sample_automation.yml') }
      subject { Config }

      it "parses the YAML in the automation_config_path" do
        subject.stub(:automation_config_path).and_return(stub_path)
        subject.attributes_from_file.should == YAML.load_file(stub_path)
      end
    end

    context ".automation_config_path" do
      subject { Config }

      it "is the .automation.yml file in the project directory" do
        subject.automation_config_path.should == File.join(Dir.pwd, subject::FILE_NAME)
      end

      it "is the .automation.yml file in the project directory, two directories up" do
        Dir.chdir "spec/support"
        subject.automation_config_path.should == File.join(Dir.pwd, subject::FILE_NAME)
      end

      it "gives up on .automation.yml once it is not able to keep going up" do
        back_to_project = Dir.pwd
        File.stub(:exists?) { false }
        Automation::CLI.should_receive(:say).with("Could not find #{subject::FILE_NAME}")
        lambda { subject.automation_config_path }.should raise_error(SystemExit)
        Dir.chdir back_to_project
      end
    end

    context "#current_app?" do
      before do
        subject.stub(:engine_yard_app_name).and_return("ngin")
      end
      it "returns true if the argument matches the app name" do
        subject.current_app?(:ngin).should be_true
      end

      it "returns false if the argument doesn't match the app name" do
        subject.current_app?("stat-ngin").should be_false
      end

    end

    context "#remote_branch_exists?" do
      before do
        Automation::CLI.stub(:perform => <<-BR
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

    context "#servers" do
      before do
        # load the cached file stored in spec/support
        subject.stub(:api_object => api)
      end

      let(:api) { Marshal.load File.read cache_path }
      let(:sample_app) { api.apps.named("stat_ngin") }
      let(:sample_environment) { sample_app.environments.first }
      let(:sample_instance) { sample_environment.instances.first }
      let(:instance_attributes) {
        {
          "amazon_id" => sample_instance.amazon_id,
          "hostname" => sample_instance.hostname,
          "name" => sample_instance.name,
          "role" => sample_instance.role,
        }
      }

      it "returns a hash with the app names as keys" do
        subject.servers.keys.sort.should == api.apps.map(&:name).sort
      end

      it "returns a hash of environments within the value for each app" do
        subject.servers[sample_app.name].keys.sort.should == sample_app.environments.map(&:name).sort
      end

      it "returns a hash of instances within the value for each environment" do
        expected = sample_environment.instances.map{|instance| subject.instance_key(instance) }.sort
        subject.servers[sample_app.name][sample_environment.name].keys.sort.should == expected
      end

      it "returns a hash of attributes for each instance" do
        instance_attributes.each do |key, value|
          subject.servers[sample_app.name][sample_environment.name][subject.instance_key(sample_instance)][key].should == value
        end
      end
    end

    describe "#instance_key(instance)" do
      let(:instance) { stub(role: "role", name: "name", hostname: "hostname", amazon_id: "amazon_id")}

      it "returns a string with uniq information for the instance" do
        subject.instance_key(instance).should == "#{instance.role} #{instance.name} #{instance.hostname} #{instance.amazon_id}"
      end
    end

    context "#api_object" do
      let(:data) { stub }

      it "defers to the EngineYardAPI class" do
        EngineYardAPI.should_receive(:fetch) { data }
        subject.api_object
      end
    end

    context "#reload_cached_api_object" do
      it "devers to the EngineYardAPI class" do
        EngineYardAPI.should_receive(:reload_cached_api_object)
        subject.reload_cached_api_object
      end
    end

    context "#infrastructure?" do
      it "returns true if the infrastructure key is present" do
        File.should_receive(:exist?).with(Config::INFRASTRUCTURE_KEY).and_return(true)
        subject.infrastructure?.should be_true
      end

      it "returns false if the infrastructure key is not present" do
        File.should_receive(:exist?).with(Config::INFRASTRUCTURE_KEY).and_return(false)
        subject.infrastructure?.should be_false
      end
    end

    context "#engine_yard_app_name=(name)" do
      let(:new_value) { "new_value" }
      subject { Config.parse }

      it "overwrites the value inferred from .automation.yml" do
        old_value = subject.engine_yard_app_name
        subject.engine_yard_app_name = new_value
        subject.engine_yard_app_name.should == new_value
      end
    end

    context "#app_name" do
      it "returns the cloud_ngin_app_name if it has one" do
        config = Config.new(cloud_ngin_app_name: "foo")
        config.app_name.should == "foo"
      end

      it "returns the engine_yard_app_name if it has one" do
        config = Config.new(engine_yard_app_name: "bar")
        config.app_name.should == "bar"
      end

      it "returns the directory name otherwise" do
        config = Config.new
        config.app_name.should == config.basedir
      end
    end

    context "#basedir" do
      it "returns the name of the directory containing the .automation.yml file" do
        config = Config.new
        expected_value = File.basename(File.dirname(Config.automation_config_path))
        config.basedir.should == expected_value
      end
    end
  end
end
