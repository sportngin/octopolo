require "erb"
require "ostruct"

module Automation
  class Renderer
    # Constants for the template file names
    PULL_REQUEST_BODY = "pull_request_body"

    # Public: Render a given ERB template
    #
    # template - A String contianing the name of the ERB template
    # locals - A Hash containing variables to render. The keys must match the variable names in the template
    #
    # Lifted from [Stack Overflow](http://stackoverflow.com/questions/8954706/render-an-erb-template-with-values-from-a-hash)
    #
    # Example
    #
    #   render "first_last_name_template", {first: "Bob", last: "Person"}
    #   # => "Bob Person"
    #
    # Returns a String containing the rendered template
    def self.render template, locals
      # template_string, safe_mode = 0, "-" to trim whitespace in ERB tags ending -%> (like Rails)
      ERB.new(contents_of(template), 0, "-").result(OpenStruct.new(locals).instance_eval { binding })
    end

    # Public: The contents of the named template
    def self.contents_of template
      File.read File.join(template_base_path, "#{template}.erb")
    end

    # Public: Path to the directory containing the templates
    def self.template_base_path
      File.expand_path(File.join(__FILE__, "../templates"))
    end
  end
end
