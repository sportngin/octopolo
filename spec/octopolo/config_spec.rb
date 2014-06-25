require "spec_helper"

module Octopolo
  describe Config do
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
      subject { Config }

      it "is the .octopolo.yml file in the project directory" do
        subject.octopolo_config_path.should == File.join(Dir.pwd, subject::FILE_NAME)
      end

      it "is the .octopolo.yml file in the project directory, two directories up" do
        Dir.chdir "spec/support"
        subject.octopolo_config_path.should == File.join(Dir.pwd, subject::FILE_NAME)
      end

      it "gives up on .octopolo.yml once it is not able to keep going up" do
        back_to_project = Dir.pwd
        File.stub(:exists?) { false }
        Octopolo::CLI.should_receive(:say).with("Could not find #{subject::FILE_NAME}")
        lambda { subject.octopolo_config_path }.should raise_error(SystemExit)
        Dir.chdir back_to_project
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
      it "returns the name of the directory containing the .octopolo.yml file" do
        config = Config.new
        expected_value = File.basename(File.dirname(Config.octopolo_config_path))
        config.basedir.should == expected_value
      end
    end
  end
end
