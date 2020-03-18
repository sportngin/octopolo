require "spec_helper"
require "octopolo/scripts/octopolo_setup"

module Octopolo
  module Scripts
    describe OctopoloSetup do
      let(:config) { double(:config) }
      let(:cli) { double(:cli) }
      let(:user_config) { double(:user_config) }

      subject { OctopoloSetup }

      before do
        subject.config = config
        subject.cli = cli
        subject.user_config = user_config
      end

      context ".invoke" do
        it "ensures that git extras is installed" do
          expect(subject).to receive(:verify_git_extras_setup)
          expect(subject).to receive(:verify_user_setup)

          subject.invoke
        end
      end

      context ".verify_git_extras_setup" do
        it "installs git-extras if it is not already installed" do
          expect(subject).to receive(:git_extras_installed?) { false }
          expect(subject).to receive(:install_git_extras)
          subject.verify_git_extras_setup
        end

        it "does nothing if git-extras is already installed" do
          expect(subject).to receive(:git_extras_installed?) { true }
          expect(subject).to receive(:install_git_extras).never
          subject.verify_git_extras_setup
        end
      end

      context ".git_extras_installed?" do
        it "returns true if git-extras command exists" do
          expect(cli).to receive(:perform).with("which git-extras", false) { "/usr/local/lib/git-extras" }
          expect(subject.git_extras_installed?).to be_truthy
        end

        it "returns false if git-extras command does not exist" do
          expect(cli).to receive(:perform).with("which git-extras", false) { "" }
          expect(subject.git_extras_installed?).to be_falsey
        end
      end

      context ".install_git_extras" do
        it "installs git-extras through homebrew" do
          expect(cli).to receive(:say).with("Updating Homebrew to ensure latest git-extras formula.")
          expect(cli).to receive(:perform).with("brew update")
          expect(cli).to receive(:say).with("Installing git-extras")
          expect(cli).to receive(:perform).with("brew install git-extras")

          subject.install_git_extras
        end
      end

      context ".verify_user_setup" do
        it "verifies that the user's full name and github credentials are set up" do
          expect(subject).to receive(:verify_user_full_name)
          expect(subject).to receive(:verify_user_github_credentials)

          subject.verify_user_setup
        end
      end

      context ".verify_user_full_name" do
        let(:name) { "Joe Person" }

        it "does nothing if the full name is configured" do
          allow(user_config).to receive_messages(full_name: name)
          expect(cli).to receive(:say).with("Full name '#{name}' already configured.")
          expect(cli).to receive(:prompt).never
          expect(user_config).to receive(:full_name=).never

          subject.verify_user_full_name
        end

        it "asks and stores the full name if not configured" do
          allow(user_config).to receive_messages(full_name: ENV["USER"])
          expect(cli).to receive(:prompt).with("Your full name:") { name }
          expect(user_config).to receive(:full_name=).with(name)

          subject.verify_user_full_name
        end
      end

      context ".verify_user_github_credentials" do
        it "does nothing if github credentials are set" do
          expect(GitHub).to receive(:check_connection)
          expect(GithubAuth).not_to receive(:invoke)
          expect(cli).to receive(:say).with("Successfully configured API token.")

          subject.verify_user_github_credentials
        end

        it "prompts to set up authentication otherwise" do
          expect(GitHub).to receive(:check_connection).and_raise(GitHub::BadCredentials.new "token rejected")
          expect(cli).to receive(:say).with("token rejected")
          expect(GithubAuth).not_to receive(:invoke)

          subject.verify_user_github_credentials
        end

        it "does nothing if it gets TryAgain" do
          expect(GitHub).to receive(:check_connection).and_raise(GitHub::TryAgain.new "no token. make one and try again.")
          expect(cli).to receive(:say).with("no token. make one and try again.")
          expect { subject.verify_user_github_credentials }.to_not raise_error
        end
      end
    end
  end
end
