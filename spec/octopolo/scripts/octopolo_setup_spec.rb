require "spec_helper"
require "octopolo/scripts/octopolo_setup"

module Octopolo
  module Scripts
    describe OctopoloSetup do
      let(:config) { stub(:config) }
      let(:cli) { stub(:cli) }
      let(:user_config) { stub(:user_config) }

      subject { OctopoloSetup }

      before do
        subject.config = config
        subject.cli = cli
        subject.user_config = user_config
      end

      context ".invoke" do
        it "ensures that git extras is installed" do
          subject.should_receive(:verify_git_extras_setup)
          subject.should_receive(:verify_user_setup)

          subject.invoke
        end
      end

      context ".verify_git_extras_setup" do
        it "installs git-extras if it is not already installed" do
          subject.should_receive(:git_extras_installed?) { false }
          subject.should_receive(:install_git_extras)
          subject.verify_git_extras_setup
        end

        it "does nothing if git-extras is already installed" do
          subject.should_receive(:git_extras_installed?) { true }
          subject.should_receive(:install_git_extras).never
          subject.verify_git_extras_setup
        end
      end

      context ".git_extras_installed?" do
        it "returns true if git-extras command exists" do
          cli.should_receive(:perform).with("which git-extras", false) { "/usr/local/lib/git-extras" }
          subject.git_extras_installed?.should be true
        end

        it "returns false if git-extras command does not exist" do
          cli.should_receive(:perform).with("which git-extras", false) { "" }
          subject.git_extras_installed?.should be false
        end
      end

      context ".install_git_extras" do
        it "installs git-extras through homebrew" do
          cli.should_receive(:say).with("Updating Homebrew to ensure latest git-extras formula.")
          cli.should_receive(:perform).with("brew update")
          cli.should_receive(:say).with("Installing git-extras")
          cli.should_receive(:perform).with("brew install git-extras")

          subject.install_git_extras
        end
      end

      context ".verify_user_setup" do
        it "verifies that the user's full name and github credentials are set up" do
          subject.should_receive(:verify_user_full_name)
          subject.should_receive(:verify_user_github_credentials)

          subject.verify_user_setup
        end
      end

      context ".verify_user_full_name" do
        let(:name) { "Joe Person" }

        it "does nothing if the full name is configured" do
          user_config.stub(full_name: name)
          cli.should_receive(:say).with("Full name '#{name}' already configured.")
          cli.should_receive(:prompt).never
          user_config.should_receive(:full_name=).never

          subject.verify_user_full_name
        end

        it "asks and stores the full name if not configured" do
          user_config.stub(full_name: ENV["USER"])
          cli.should_receive(:prompt).with("Your full name:") { name }
          user_config.should_receive(:full_name=).with(name)

          subject.verify_user_full_name
        end
      end

      context ".verify_user_github_credentials" do
        it "does nothing if github credentials are set" do
          GitHub.should_receive(:check_connection)
          GithubAuth.should_not_receive(:invoke)
          cli.should_receive(:say).with("Successfully configured API token.")

          subject.verify_user_github_credentials
        end

        it "prompts to set up authentication otherwise" do
          GitHub.should_receive(:check_connection).and_raise(GitHub::BadCredentials.new "token rejected")
          cli.should_receive(:say).with("token rejected")
          GithubAuth.should_not_receive(:invoke)

          subject.verify_user_github_credentials
        end

        it "does nothing if it gets TryAgain" do
          GitHub.should_receive(:check_connection).and_raise(GitHub::TryAgain.new "no token. make one and try again.")
          cli.should_receive(:say).with("no token. make one and try again.")
          expect { subject.verify_user_github_credentials }.to_not raise_error
        end
      end
    end
  end
end
