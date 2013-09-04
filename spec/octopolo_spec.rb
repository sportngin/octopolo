require "spec_helper"

describe Octopolo do
  it "has a VERSION" do
    Octopolo::VERSION.should_not be_nil
  end

  context ".require_if_installed" do
    it "requires the given module" do
      # Matrix is an arbitrary standard library module we don't use so it won't
      # be required yet, used to test that the require actually happens
      expect { Matrix }.to raise_error
      require_if_installed "matrix"
      expect { Matrix }.to_not raise_error
    end

    it "fails silently if given module is not installed" do
      expect { require_if_installed "adsfasdfasefasefasefaef" }.to_not raise_error
    end
  end
end
