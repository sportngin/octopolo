module Octopolo
  class Validator
    include CLIWrapper
    include ConfigWrapper

    attr_accessor :validations

    def initialize()
      @validations = config.validations
    end

    def is_valid?
      if @validations.nil? || @validations.size == 0
        cli.say 'No validations configured.  Assuming your code is perfect.'
      else
        validate
        cli.say 'All validations passed.'
      end
      return true
    end

    def validate
      @validations.each do |validation|
        cli.perform validation
      end
    end
  end
end
