require "open3"
require "highline"

module Octopolo
  # Public: Class to perform cli-related tasks, like performing commands.
  class CLI
    # Public: Perform the given shell command.
    #
    # command - A String containing the command to perform.
    # say_command - A Boolean determining whether to display the performed command to the screen. (default: true)
    # ignore_non_zero - Ignore exception for non-zero exit status of command.
    #
    # Examples
    #
    #   CLI.perform "git pull", false
    #   git pull
    #   Already up-to-date.
    #   # => "Already up-to-date."
    #
    #   CLI.perform "git pull", false
    #   # => "Already up-to-date."
    #
    # Returns the output of the command as a String.
    def self.perform(command, say_command = true, ignore_non_zero=false)
      # display the command
      say command if say_command
      # and then perform it
      if Open3.respond_to?(:capture3)
        output, error, status = Open3.capture3(command)
        raise "command=#{command}; exit_status=#{status.exitstatus}; stderr=#{error}" unless status.success? || ignore_non_zero
      else
        # Only necessary as long as we use 1.8.7, which doesn't have Open3.capture3
        output = `#{command}`
      end

      # speak the output
      say output if say_command
      # return the output of the command
      output
    end

    # Public: Perform the command, but do not print out the command
    #
    # command - A String containing the command to perform.
    #
    # Examples
    #
    #   CLI.perform_quietly "git pull"
    #   Already up-to-date.
    #   # => "Already up-to-date."
    def self.perform_quietly command
      perform command, false
    end

    # Public: Replace the current process with the given shell command.
    #
    # command - A String containing the command to perform.
    #
    # Returns nothing and exits the current Ruby process.
    def self.perform_and_exit(command)
      say command
      # Kernel#exec replaces the ruby process with the new bash process
      # executing the command. This is useful for us mainly for things like
      # calling `ssh` which will be interactive or `hub` which will open a text
      # editor. Those commands don't play well with Kernel#` or Open3.capture3.
      exec command
    end

    # Public: Display the given message.
    #
    # message - A String containig the message to display.
    #
    # Examples
    #
    #   CLI.say "About to do something awesome"
    #
    #   CLI.say "This may take a moment..."
    #
    # Returns nothing.
    def self.say(message)
      unless message.nil? || message.empty?
        puts message
      end
    end

    # Public: Display a blank line
    def self.spacer_line
      say " "
    end

    # Public: Perform a set of commands in the given directory.
    #
    # Yields nothing.
    #
    # dir - A String indicating the path to perform the commands in.
    #
    # Examples
    #
    #   CLI.perform_in "~" do
    #     CLI.perform "rm -Rf"
    #   end
    #
    #   CLI.perform_in "/tmp" do
    #     CLI.perform "ls"
    #   end
    #
    # Returns nothing.
    def self.perform_in(dir)
      say "Performing in #{dir}:"
      Dir.chdir(dir) do
        yield
      end
    end

    def self.ask(question, choices)
      return choices.first if choices.size == 1
      
      say question
      choices.each_with_index do |choice, i|
        say "#{i+1}) #{choice}"
      end

      selection = nil
      while not choices.include?(selection)
        selection = prompt
        break if choices.include?(selection) # passed in the value of the choice
        selection_index = selection.to_i - 1 # passed in a 1-based index of the choice
        selection = choices[selection_index] if selection_index >= 0 # gather the value of the choice
        break if choices.include?(selection)
        say "Not a valid choice."
      end

      selection
    end

    # Public: Ask a yes or no question
    #
    # question - The question to display to the user in the prompt
    #
    # Returns a Boolean
    def self.ask_boolean(question)
      answer = prompt("#{question} (y/n)")
      # Return true if the answer starts with "Y" or "y"; else return false
      !!(answer =~ /^y/i)
    end

    def self.prompt(prompt_text="> ")
      highline.ask prompt_text do |conf|
        conf.readline = true
      end.to_s
    end

    # Public: Prompt user for multiple lines of input
    #
    # prompt_text - The text to display before the prompt
    #
    # Example:
    #
    #   # Accept multiple lines of text, with the prompt "QA Plan:"
    #   plan = CLI.prompt_multiline "QA Plan:"
    #
    # Returns a String containing the value the user entered
    def self.prompt_multiline(prompt_text)
      highline.ask(prompt_text) do |conf|
        # accept text until the first blank line (instead of stopping at the
        # first newline), to allow multiple lines of input
        conf.gather = ""
        conf.readline = true
      end
    end

    # Public: Prompt user for input, but do not display what they type
    #
    # prompt_text - The text to display before the prompt; e.g., "Password: "
    #
    # Returns a String containing the value the user entered
    def self.prompt_secret(prompt_text)
      highline.ask(prompt_text) do |conf|
        # do not display the text input
        conf.echo = false
        conf.readline = true
      end
    end

    def self.copy_to_clipboard(input)
      say "Putting '#{input}' on the clipboard."
      # have to do this all roundy-abouty by passing to /bin/bash, because by default, ruby performs commands with /bin/sh, which doesn't respect the -n flag on echo
      # http://stackoverflow.com/questions/5059039/ruby-execute-shell-command-echo-with-n-option
      perform "/bin/bash -c 'echo -n #{input}' | pbcopy", false
    end

    # Public: Open the given path with Mac OS X's built-in `open` command
    def self.open path
      perform_and_exit "open '#{path}'"
    end

    # Public: Instantiate an instance of HighLine
    #
    # This is likely a temporary method until we replace a lot of CLI's guts
    # with HighLine equivalents.
    #
    # Returns an instance of HighLine
    def self.highline
      HighLine.new
    end
  end
end
