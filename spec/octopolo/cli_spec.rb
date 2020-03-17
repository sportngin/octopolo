require "spec_helper"

module Octopolo
  describe CLI do
    subject { CLI }

    context ".perform(command)" do
      let(:command) { "ls" }
      let(:result) { "result" }
      let(:error) { "error message" }
      let(:exception_message) { "Error with something" }
      let(:status_success) { double("status", "success?" => true, :exitstatus => 0) }
      let(:status_error) { double("status", "success?" => nil, :exitstatus => 1) }

      it "passes the given command to the shell" do
        expect(subject).to receive(:say).with(command)
        expect(Open3).to receive(:capture3).with(command).and_return([result, nil, status_success])
        expect(subject).to receive(:say).with(result)
        expect(subject.perform(command)).to eq(result)
      end

      it "uses Kernel#` if Open3 has no capture3 method (e.g., Ruby 1.8.7)" do
        expect(subject).to receive(:say).with(command)
        # simulating ruby 1.8.7 not having an Open3.capture3 method
        expect(Open3).to receive(:respond_to?).with(:capture3).and_return(false)
        expect(subject).to receive(:`).with(command).and_return(result)
        expect(subject).to receive(:say).with(result)
        expect(subject.perform(command)).to eq(result)
      end

      it "should raise exception" do
        expect(subject).to receive(:say).with(command)
        expect(Open3).to receive(:capture3).with(command).and_raise(exception_message)
        expect { subject.perform(command) }.to raise_error(RuntimeError, exception_message)
      end

      it "should raise errors from command" do
        expect(subject).to receive(:say).with(command)
        expect(Open3).to receive(:capture3).with(command).and_return([result, "kaboom", status_error])
        expect { subject.perform(command) }
            .to raise_error(RuntimeError, "command=#{command}; exit_status=1; stderr=kaboom")
      end

      it "should ignore non zero return from command" do
        expect(subject).to receive(:say).with(command)
        expect(Open3).to receive(:capture3).with(command).and_return([result, "kaboom", status_error])
        expect(subject).to receive(:say).with(result)
        expect { subject.perform(command, true, true) }.to_not raise_error
      end

      it "should not speak the command if told not to" do
        expect(subject).to receive(:say).with(command).never
        subject.perform(command, false)
      end
    end

    context ".perform_quietly(command)" do
      let(:command) { "ls" }

      it "performs the command without displaying itself" do
        expect(subject).to receive(:perform).with(command, false)
        subject.perform_quietly(command)
      end
    end

    context ".perform_and_exit(command)" do
      let(:command) { "ls" }

      it "should use the 'exec' command to replace the Ruby process with the command" do
        expect(subject).to receive(:say).with(command)
        expect(subject).to receive(:exec).with(command)
        subject.perform_and_exit(command)
      end
    end

    context ".say(message)" do
      let(:message) { "asdf" }

      it "displays the given message" do
        expect(subject).to receive(:puts).with(message)
        subject.say message
      end

      it "does nothing if the message is nil" do
        expect(subject).to receive(:puts).never
        subject.say nil
      end

      it "does nothing if the message is an empty string" do
        expect(subject).to receive(:puts).never
        subject.say ""
      end
    end

    context ".spacer_line" do
      it "displays a blank space" do
        expect(subject).to receive(:say).with(" ")
        subject.spacer_line
      end
    end

    context ".perform_in(dir, &block)" do
      let(:dir) { "/tmp" }
      let(:command) { "ls" }

      it "changes the script to the given directory" do
        expect(subject).to receive(:say).with("Performing in #{dir}:")
        expect(Dir).to receive(:chdir).with(dir).and_yield
        expect(subject).to receive(:perform).with(command)

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
        expect(subject).to receive(:say).with(question)
        expect(subject).to receive(:say).with("1) sandwich")
        expect(subject).to receive(:say).with("2) carrots")
        expect(subject).to receive(:say).with("3) cake")
        expect(subject).to receive(:prompt).and_return(valid_string_answer) # only specifying return value to prevent infinite loop

        subject.ask(question, choices)
      end

      it "simply returns the value if given only one choice" do
        expect(subject).to receive(:say).never
        expect(subject).to receive(:prompt).never

        expect(subject.ask(question, one_choice)).to eq(one_choice.first)
      end

      context "when answering with the string value" do
        it "returns the user's selection, if in the available choices" do
          expect(subject).to receive(:prompt).and_return(valid_string_answer)
          expect(subject.ask(question, choices)).to eq(valid_string_answer)
        end

        it "asks again if given a string other than one of the choices" do
          expect(subject).to receive(:prompt).and_return(invalid_string_answer)
          allow(subject).to receive(:say)
          expect(subject).to receive(:say).with("Not a valid choice.")
          expect(subject).to receive(:prompt).and_return(valid_string_answer)

          expect(subject.ask(question, choices)).to eq(valid_string_answer)
        end
      end

      context "when answering with the numeric value" do
        it "returns the user's selection, if in the available choices" do
          expect(subject).to receive(:prompt).and_return(valid_numeric_answer)
          allow(subject).to receive(:say)
          expect(subject.ask(question, choices)).to eq(valid_string_answer)
        end

        it "asks again if given a answer 0 or less" do
          expect(subject).to receive(:prompt).and_return(invalid_low_numeric_answer)
          expect(subject).to receive(:say).with("Not a valid choice.")
          allow(subject).to receive(:say)
          expect(subject).to receive(:prompt).and_return(valid_numeric_answer)

          expect(subject.ask(question, choices)).to eq(valid_string_answer)
        end

        it "asks again if given a answer greater than the list of choices" do
          expect(subject).to receive(:prompt).and_return(invalid_high_numeric_answer)
          expect(subject).to receive(:say).with("Not a valid choice.")
          allow(subject).to receive(:say)
          expect(subject).to receive(:prompt).and_return(valid_numeric_answer)

          expect(subject.ask(question, choices)).to eq(valid_string_answer)
        end
      end
    end

    context ".ask_boolean question" do
      let(:question) { "Are you truly happy?" }

      it "asks the question and prompts for an answer" do
        expect(subject).to receive(:prompt).with("#{question} (y/n)") { "y" }
        subject.ask_boolean(question)
      end

      it "returns true for 'y'" do
        expect(subject).to receive(:prompt) { "y" }
        expect(subject.ask_boolean(question)).to be_truthy
      end

      it "returns true for 'yes'" do
        expect(subject).to receive(:prompt) { "yes" }
        expect(subject.ask_boolean(question)).to be_truthy
      end

      it "returns true for 'Y'" do
        expect(subject).to receive(:prompt) { "Y" }
        expect(subject.ask_boolean(question)).to be_truthy
      end

      it "returns false for 'n'" do
        expect(subject).to receive(:prompt) { "n" }
        expect(subject.ask_boolean(question)).to be_falsey
      end

      it "returns false for 'no'" do
        expect(subject).to receive(:prompt) { "no" }
        expect(subject.ask_boolean(question)).to be_falsey
      end

      it "returns false for 'N'" do
        expect(subject).to receive(:prompt) { "N" }
        expect(subject.ask_boolean(question)).to be_falsey
      end
    end

    context ".prompt prompt_text" do
      let(:input) { "asdf" }
      let(:highline) { double }
      let(:prompt_text) { "Foo: " }

      before do
        allow(subject).to receive_messages(highline: highline)
      end

      it "retrieves response from the user" do
        expect(highline).to receive(:ask).with("> ").and_return(input)

        expect(subject.prompt).to eq(input)
      end

      it "uses the given text as the prompt" do
        expect(highline).to receive(:ask).with(prompt_text)

        subject.prompt prompt_text
      end
    end

    context ".prompt_secret prompt_text" do
      let(:input) { "asdf" }
      let(:prompt_text) { "Foo: " }
      let(:highline) { double }
      let(:highline_config) { double }

      before do
        allow(subject).to receive_messages(highline: highline)
      end

      it "retrieves response from the user without displaying what they type" do
        expect(highline).to receive(:ask).with(prompt_text).and_yield(highline_config).and_return(input)
        expect(highline_config).to receive(:echo=).with(false)
        expect(highline_config).to receive(:readline=).with(true)
        expect(subject.prompt_secret(prompt_text)).to eq(input)
      end
    end

    context ".prompt_multiline prompt_text" do
      let(:input) { %w(a s d f) }
      let(:prompt_text) { "Steps:" }
      let(:highline) { double }
      let(:highline_config) { double }

      before do
        allow(subject).to receive_messages(highline: highline)
      end

      it "retreives response from the user across multiple lines, returning an array of their input" do
        expect(highline).to receive(:ask).with(prompt_text).and_yield(highline_config).and_return(input)
        expect(highline_config).to receive(:gather=).with("")
        expect(highline_config).to receive(:readline=).with(true)
        expect(subject.prompt_multiline(prompt_text)).to eq(input)
      end
    end

    context ".highline" do
      let(:result) { double }

      it "instantiates a HighLine object" do
        expect(HighLine).to receive(:new) { result }
        expect(subject.highline).to eq(result)
      end
    end

    context ".open path" do
      let(:path) { "http://example.com/" }

      it "exits and opens the path with Mac OS X's `open` command" do
        expect(subject).to receive(:perform_and_exit).with("open '#{path}'")
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
          expect(subject).to receive(:say).with("Putting '#{input}' on the clipboard.")
          subject.copy_to_clipboard input
          # and to test that it's on the clipboard
          expect(`pbpaste`).to eq(input)
        end
      end
    end
  end
end
