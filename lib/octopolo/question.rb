module Octopolo
  class Question
    include CLIWrapper

    attr_accessor :prompt, :type, :choices, :add_label_based_on_boolean

    def initialize(options)
      # self.cli = options[:cli]
      self.prompt = options[:prompt]
      self.type = options[:type] || nil
      self.choices = options[:choices] || nil
      self.add_label_based_on_boolean = options[:add_label_based_on_boolean] || nil
    end

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

    def ask
      cli.ask(@prompt, choices)
    end

    def ask_boolean
      response = cli.ask_boolean(@prompt)

      if response && @add_label_based_on_boolean
        @add_label_based_on_boolean[:label_name]
      else
        response
      end
    end

    def prompt
      cli.prompt(@prompt)
    end

    def prompt_multiline
      cli.prompt_multiline(@prompt)
    end

    def prompt_secret
      cli.prompt_secret(@prompt)
    end
  end
end
