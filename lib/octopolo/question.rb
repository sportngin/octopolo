module Octopolo
  class Question
    include CLIWrapper

    attr_accessor :prompt, :type, :choices, :add_label_based_on_boolean

    def initialize(options)
      # TODO: remove this puts statement
      puts "Verifying I'm running new version of Octopolo."
      self.prompt = options[:prompt]
      self.type = options[:type] || nil
      self.choices = options[:choices] || nil
      self.add_label_based_on_boolean = options[:add_label_based_on_boolean] || nil
    end

    # Runs the question method based on what the :type was initialized as.
    def run_based_on_type
      case @type
      when :ask
        ask
      when :ask_boolean
        ask_boolean
      when :prompt
        prompt
      when :prompt_multiline
        prompt_multiline
      when :prompt_secret
        prompt_secret
      else
        "Question type is invalid... not asking a question."
      end
    end

    # Asks the client to ask the question and returns the answer in string form.
    def ask
      cli.ask(@prompt, @choices)
    end

    # Asks the client to ask the true/false question and returns the answer in boolean form UNLESS we get
    # true and we want to add a label, in which case it will return the name of the label
    # in string form.
    def ask_boolean
      response = cli.ask_boolean(@prompt)

      if response && @add_label_based_on_boolean
        @add_label_based_on_boolean[:label_name]
      else
        response
      end
    end

    # Asks the client to ask the question and returns the answer in string form.
    def prompt
      cli.prompt(@prompt)
    end

    # Asks the client to ask the question and returns the answer in string form.
    def prompt_multiline
      cli.prompt_multiline(@prompt)
    end

    # Asks the client to ask the question and returns the answer in string form.
    def prompt_secret
      cli.prompt_secret(@prompt)
    end
  end
end
