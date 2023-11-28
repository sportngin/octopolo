require_relative "../../lib/octopolo/renderer"

module Octopolo
  describe Renderer do
    context ".render template, locals" do
      let(:locals) { {foo: "bar"} }
      let(:template_name) { "some_template" }
      let(:template_contents) { "<%= foo %>" }

      it "renders the given template name with the given local variables" do
        Renderer.should_receive(:contents_of).with(template_name) { template_contents }
        rendered = Renderer.render(template_name, locals)
        rendered.should eq(locals[:foo])
      end
    end

    context ".template_base_path" do
      it "should be in the octopolo directory" do
        Renderer.template_base_path.should eq(File.expand_path(File.join(__FILE__, "../../../lib/octopolo/templates")))
      end
    end

    context ".contents_of template" do
      let(:contents) { double(:erb) }
      let(:name) { "some_template" }
      let(:path) { File.join(Renderer.template_base_path, "#{name}.erb") }

      it "reads the file from templates/" do
        File.should_receive(:read).with(path) { contents }
        Renderer.contents_of(name).should eq(contents)
      end
    end
  end
end
