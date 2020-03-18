require_relative "../../lib/octopolo/question"

describe Octopolo::Question do
  let(:prompt_1) do
    {
      prompt: "test-prompt",
      type: :ask,
      choices: ["choice1", "choice2"]
    }
  end

  let(:prompt_2) do
    {
      prompt: "test-prompt",
      type: :ask_boolean
    }
  end

  let(:prompt_label) do
    {
      prompt:"test-prompt",
      type: :ask_boolean,
      add_label_based_on_boolean: {
        label_name: "test_label"
      }
    }
  end

  let(:prompt_3) do
    {
      prompt: "test-prompt",
      type: :prompt
    }
  end


  let(:prompt_4) do
    {
      prompt: "test-prompt",
      type: :prompt_multiline
    }
  end


  let(:prompt_5) do
    {
      prompt: "test-prompt",
      type: :prompt_secret
    }
  end

  let(:cli) { double(:cli) }

  before do
    allow_any_instance_of(Octopolo::Question).to receive_messages({
      :cli => cli
    })
  end

  describe "#ask" do
    it "should have the client call .ask" do
      expect(cli).to receive(:ask) {"1"}
      Octopolo::Question.new(prompt_1).ask
    end
  end

  describe "#ask_boolean" do
    it "should have the client call .ask_boolean" do
      expect(cli).to receive(:ask_boolean) {"yes"}
      Octopolo::Question.new(prompt_2).ask_boolean
    end

    describe "we don't want to add a label" do
      it "should return the boolean response the client returns: false" do
        allow(cli).to receive(:ask_boolean) {false}
        resp = Octopolo::Question.new(prompt_2).ask_boolean
        expect(resp).to eq(false)
      end

      it "should return the boolean response the client returns: true" do
        allow(cli).to receive(:ask_boolean) {true}
        resp = Octopolo::Question.new(prompt_2).ask_boolean
        expect(resp).to eq(true)
      end
    end

    describe "we do want to add a label" do
      it "should return the name of the label if client returns true" do
        allow(cli).to receive(:ask_boolean) {true}
        resp = Octopolo::Question.new(prompt_label).ask_boolean
        expect(resp).to eq("test_label")
      end
    end
  end

  describe "#prompt" do
    it "should have the client call .prompt" do
      expect(cli).to receive(:prompt) {"yes"}
      Octopolo::Question.new(prompt_3).prompt
    end
  end

  describe "#prompt_multiline" do
    it "should have the client call .prompt_multiline" do
      expect(cli).to receive(:prompt_multiline) {"yes"}
      Octopolo::Question.new(prompt_4).prompt_multiline
    end
  end

  describe "#prompt_secret" do
    it "should have the client call .prompt_secret" do
      expect(cli).to receive(:prompt_secret) {"yes"}
      Octopolo::Question.new(prompt_5).prompt_secret
    end
  end
end
