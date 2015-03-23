require "spec_helper"

module Octopolo
  describe CLI do
    subject { CLI }

    context ".perform(command)" do
      let(:command) { "ls" }
      let(:result) { "result" }
      let(:error) { "error message" }
      let(:exception_message) { "Error with something" }

      it "passes the given command to the shell" do
        subject.should_receive(:say).with(command)
        Open3.should_receive(:capture3).with(command).and_return([result, nil])
        subject.should_receive(:say).with(result)
        subject.perform(command).should == result
      end

      it "uses Kernel#` if Open3 has no capture3 method (e.g., Ruby 1.8.7)" do
        subject.should_receive(:say).with(command)
        # simulating ruby 1.8.7 not having an Open3.capture3 method
        Open3.should_receive(:respond_to?).with(:capture3).and_return(false)
        subject.should_receive(:`).with(command).and_return(result)
        subject.should_receive(:say).with(result)
        subject.perform(command).should == result
      end

      it "should handle exception gracefully" do
        subject.should_receive(:say).with(command)
        Open3.should_receive(:capture3).with(command).and_raise(exception_message)
        subject.should_receive(:say).with("Unable to perform '#{command}': #{exception_message}")
        subject.perform(command).should be_nil
      end

      it "should handle errors gracefully" do
        subject.should_receive(:say).with(command)
        Open3.should_receive(:capture3).with(command).and_return([result, "kaboom", 1])
        subject.should_receive(:say).with("Unable to perform '#{command}': exit_status=1; stderr=kaboom")
        subject.perform(command).should be_nil
      end

      it "should not speak the command if told not to" do
        subject.should_receive(:say).with(command).never
        subject.perform(command, false)
      end
    end

    context ".perform_quietly(command)" do
      let(:command) { "ls" }

      it "performs the command without displaying itself" do
        subject.should_receive(:perform).with(command, false)
        subject.perform_quietly(command)
      end
    end

    context ".perform_and_exit(command)" do
      let(:command) { "ls" }

      it "should use the 'exec' command to replace the Ruby process with the command" do
        subject.should_receive(:say).with(command)
        subject.should_receive(:exec).with(command)
        subject.perform_and_exit(command)
      end
    end

    context ".say(message)" do
      let(:message) { "asdf" }

      it "displays the given message" do
        subject.should_receive(:puts).with(message)
        subject.say message
      end

      it "does nothing if the message is nil" do
        subject.should_receive(:puts).never
        subject.say nil
      end

      it "does nothing if the message is an empty string" do
        subject.should_receive(:puts).never
        subject.say ""
      end
    end

    context ".spacer_line" do
      it "displays a blank space" do
        subject.should_receive(:say).with(" ")
        subject.spacer_line
      end
    end

    context ".perform_in(dir, &block)" do
      let(:dir) { "/tmp" }
      let(:command) { "ls" }

      it "changes the script to the given directory" do
        subject.should_receive(:say).with("Performing in #{dir}:")
        Dir.should_receive(:chdir).with(dir).and_yield
        subject.should_receive(:perform).with(command)

        subject.perform_in(dir) do
          subject.perform(command)
        end
      end
    end

    context ".ask(question, choices)" do
      let(:question) { "What do you want to eat?" }
      let(:choices) { ["sandwich", "carrots", "cake"] }
      let(:one_choice) { [choices.first] }
      let(:valid_string_answer) { choices[valid_numeric_answer - 1] }
      let(:invalid_string_answer) { "pineapple" }
      # answers start at 1, not at 0, so +1
      let(:valid_numeric_answer) { rand(choices.size) + 1 }
      let(:invalid_low_numeric_answer) { 0 }
      let(:invalid_high_numeric_answer) { choices.size + 2 }

      it "provides the given list of choices for the given question" do
        subject.should_receive(:say).with(question)
        subject.should_receive(:say).with("1) sandwich")
        subject.should_receive(:say).with("2) carrots")
        subject.should_receive(:say).with("3) cake")
        subject.should_receive(:prompt).and_return(valid_string_answer) # only specifying return value to prevent infinite loop

        subject.ask(question, choices)
      end

      it "skips printing the question and choices if told not to (useful to avoid cluttering spec output)" do
        subject.should_receive(:say).with(question).never
        subject.should_receive(:say).with("1) sandwich").never
        subject.should_receive(:say).with("2) carrots").never
        subject.should_receive(:say).with("3) cake").never
        subject.should_receive(:prompt).and_return(valid_string_answer) # only specifying return value to prevent infinite loop

        subject.ask(question, choices, true)
      end

      it "simply returns the value if given only one choice" do
        subject.should_receive(:say).never
        subject.should_receive(:prompt).never

        subject.ask(question, one_choice).should == one_choice.first
      end

      context "when answering with the string value" do
        it "returns the user's selection, if in the available choices" do
          subject.should_receive(:prompt).and_return(valid_string_answer)
          subject.ask(question, choices, true).should == valid_string_answer
        end

        it "asks again if given a string other than one of the choices" do
          subject.should_receive(:prompt).and_return(invalid_string_answer)
          subject.should_receive(:say).with("Not a valid choice.")
          subject.should_receive(:prompt).and_return(valid_string_answer)

          subject.ask(question, choices, true).should == valid_string_answer
        end
      end

      context "when answering with the numeric value" do
        it "returns the user's selection, if in the available choices" do
          subject.should_receive(:prompt).and_return(valid_numeric_answer)
          subject.ask(question, choices, true).should == valid_string_answer
        end

        it "asks again if given a answer 0 or less" do
          subject.should_receive(:prompt).and_return(invalid_low_numeric_answer)
          subject.should_receive(:say).with("Not a valid choice.")
          subject.should_receive(:prompt).and_return(valid_numeric_answer)

          subject.ask(question, choices, true).should == valid_string_answer
        end

        it "asks again if given a answer greater than the list of choices" do
          subject.should_receive(:prompt).and_return(invalid_high_numeric_answer)
          subject.should_receive(:say).with("Not a valid choice.")
          subject.should_receive(:prompt).and_return(valid_numeric_answer)

          subject.ask(question, choices, true).should == valid_string_answer
        end
      end
    end

    context ".ask_boolean question" do
      let(:question) { "Are you truly happy?" }

      it "asks the question and prompts for an answer" do
        subject.should_receive(:prompt).with("#{question} (y/n)") { "y" }
        subject.ask_boolean(question)
      end

      it "returns true for 'y'" do
        subject.should_receive(:prompt) { "y" }
        subject.ask_boolean(question).should be_true
      end

      it "returns true for 'yes'" do
        subject.should_receive(:prompt) { "yes" }
        subject.ask_boolean(question).should be_true
      end

      it "returns true for 'Y'" do
        subject.should_receive(:prompt) { "Y" }
        subject.ask_boolean(question).should be_true
      end

      it "returns false for 'n'" do
        subject.should_receive(:prompt) { "n" }
        subject.ask_boolean(question).should be_false
      end

      it "returns false for 'no'" do
        subject.should_receive(:prompt) { "no" }
        subject.ask_boolean(question).should be_false
      end

      it "returns false for 'N'" do
        subject.should_receive(:prompt) { "N" }
        subject.ask_boolean(question).should be_false
      end
    end

    context ".prompt prompt_text" do
      let(:input) { "asdf" }
      let(:highline) { stub }
      let(:prompt_text) { "Foo: " }

      before do
        subject.stub(highline: highline)
      end

      it "retrieves response from the user" do
        highline.should_receive(:ask).with("> ").and_return(input)

        subject.prompt.should == input
      end

      it "uses the given text as the prompt" do
        highline.should_receive(:ask).with(prompt_text)

        subject.prompt prompt_text
      end
    end

    context ".prompt_secret prompt_text" do
      let(:input) { "asdf" }
      let(:prompt_text) { "Foo: " }
      let(:highline) { stub }
      let(:highline_config) { stub }

      before do
        subject.stub(highline: highline)
      end

      it "retrieves response from the user without displaying what they type" do
        highline.should_receive(:ask).with(prompt_text).and_yield(highline_config).and_return(input)
        highline_config.should_receive(:echo=).with(false)
        highline_config.should_receive(:readline=).with(true)
        subject.prompt_secret(prompt_text).should == input
      end
    end

    context ".prompt_multiline prompt_text" do
      let(:input) { %w(a s d f) }
      let(:prompt_text) { "Steps:" }
      let(:highline) { stub }
      let(:highline_config) { stub }

      before do
        subject.stub(highline: highline)
      end

      it "retreives response from the user across multiple lines, returning an array of their input" do
        highline.should_receive(:ask).with(prompt_text).and_yield(highline_config).and_return(input)
        highline_config.should_receive(:gather=).with("")
        highline_config.should_receive(:readline=).with(true)
        subject.prompt_multiline(prompt_text).should == input
      end
    end

    context ".highline" do
      let(:result) { stub }

      it "instantiates a HighLine object" do
        HighLine.should_receive(:new) { result }
        subject.highline.should == result
      end
    end

    context ".open path" do
      let(:path) { "http://example.com/" }

      it "exits and opens the path with Mac OS X's `open` command" do
        subject.should_receive(:perform_and_exit).with("open '#{path}'")
        subject.open path
      end
    end

    context ".copy_to_clipboard(input)" do
      let(:input) { "something#{rand(1000)}" }

      # FIXME figure out a better way to test this on non-Mac systems, which don't have pbcopy or pbpaste
      #
      # only run on the test on a mac and when not in tmux
      if RUBY_PLATFORM.include?("darwin") and !ENV['TMUX']
        it "puts the text on the system clipboard (for pasting)" do
          subject.should_receive(:say).with("Putting '#{input}' on the clipboard.")
          subject.copy_to_clipboard input
          # and to test that it's on the clipboard
          `pbpaste`.should == input
        end
      end
    end
  end
end
