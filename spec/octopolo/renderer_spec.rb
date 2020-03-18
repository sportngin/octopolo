require "spec_helper"
require_relative "../../lib/octopolo/renderer"

module Octopolo
  describe Renderer do
    context ".render template, locals" do
      let(:locals) { {foo: "bar"} }
      let(:template_name) { "some_template" }
      let(:template_contents) { "<%= foo %>" }

      it "renders the given template name with the given local variables" do
        expect(Renderer).to receive(:contents_of).with(template_name) { template_contents }
        rendered = Renderer.render(template_name, locals)
        expect(rendered).to eq(locals[:foo])
      end
    end

    context ".template_base_path" do
      it "should be in the octopolo directory" do
        expect(Renderer.template_base_path).to eq(File.expand_path(File.join(__FILE__, "../../../lib/octopolo/templates")))
      end
    end

    context ".contents_of template" do
      let(:contents) { double(:erb) }
      let(:name) { "some_template" }
      let(:path) { File.join(Renderer.template_base_path, "#{name}.erb") }

      it "reads the file from templates/" do
        expect(File).to receive(:read).with(path) { contents }
        expect(Renderer.contents_of(name)).to eq(contents)
      end
    end
  end
end
