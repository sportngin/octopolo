require "spec_helper"
require_relative "../../../lib/octopolo/github"

module Octopolo
  module GitHub
    describe User do
      context ".new login" do
        it "remembers the given login" do
          user = User.new "foo"
          expect(user.login).to eq("foo")
        end
      end

      context "#author_name" do
        let(:octo) { double }
        let(:login) { "joeuser" }
        let(:user) { User.new login }

        before do
          allow(user).to receive_messages(user_data: octo)
        end

        it "fetches the real name from GitHub" do
          allow(octo).to receive_messages(name: "Joe User")
          expect(user.author_name).to eq(octo.name)
        end

        it "returns the login if GitHub user has no name" do
          allow(octo).to receive_messages(name: nil)
          expect(user.author_name).to eq(user.login)
        end
      end

      context "#user_data" do
        let(:login) { "joeuser" }
        let(:user) { User.new login }
        let(:octo) { double }

        it "fetches the data from the User class" do
          expect(User).to receive(:user_data).with(login) { octo }
          expect(user.user_data).to eq(octo)
        end
      end

      context ".user_data login" do
        let(:base_login) { "joeuser" }
        let(:octo) { double }

        it "fetches the data from GitHub" do
          login = "#{base_login}#{rand(100000)}"
          expect(GitHub).to receive(:user).with(login) { octo }
          expect(User.user_data(login)).to eq(octo)
        end

        it "caches the data" do
          login = "#{base_login}#{rand(100000)}"
          expect(GitHub).to receive(:user).once { octo }
          User.user_data(login)
          User.user_data(login)
        end
      end

    end
  end
end
