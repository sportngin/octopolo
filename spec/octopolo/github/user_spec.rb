require "spec_helper"
require_relative "../../../lib/octopolo/github"

module Octopolo
  module GitHub
    describe User do
      context ".new login" do
        it "remembers the given login" do
          user = User.new "foo"
          user.login.should eq("foo")
        end
      end

      context "#author_name" do
        let(:octo) { double }
        let(:login) { "joeuser" }
        let(:user) { User.new login }

        before do
          user.stub(user_data: octo)
        end

        it "fetches the real name from GitHub" do
          octo.stub(name: "Joe User")
          user.author_name.should eq(octo.name)
        end

        it "returns the login if GitHub user has no name" do
          octo.stub(name: nil)
          user.author_name.should eq(user.login)
        end
      end

      context "#user_data" do
        let(:login) { "joeuser" }
        let(:user) { User.new login }
        let(:octo) { double }

        it "fetches the data from the User class" do
          User.should_receive(:user_data).with(login) { octo }
          user.user_data.should eq(octo)
        end
      end

      context ".user_data login" do
        let(:base_login) { "joeuser" }
        let(:octo) { double }

        it "fetches the data from GitHub" do
          login = "#{base_login}#{rand(100000)}"
          GitHub.should_receive(:user).with(login) { octo }
          User.user_data(login).should eq(octo)
        end

        it "caches the data" do
          login = "#{base_login}#{rand(100000)}"
          GitHub.should_receive(:user).once { octo }
          User.user_data(login)
          User.user_data(login)
        end
      end

    end
  end
end
