module Automation
  class Week
    attr_accessor :year
    attr_accessor :number

    DATE_STRING_FORMAT = "%Y-%m-%d"

    # Public: Instantiate a new Week
    #
    # year - Year the week occurs in
    # number - The number of the week in the given year
    def initialize year, number
      self.year = year
      self.number = number
    end

    # Public: Parse the date from a date-ish object
    #
    # dateish - A Date, Time, or String representing a date or time
    def self.parse dateish
      # TODO i'm not 100% happy with this implementation, but it does what i want and the tests pass
      if dateish.respond_to? :to_date
        date = dateish.to_date
        new date.year, date.cweek
      else
        date = Date.parse(dateish.to_s)
        new date.year, date.cweek
      end
    rescue ArgumentError
      raise InvalidType
    end

    # Public: Instantiate a Week for the current week
    #
    # Returns an instance of Week
    def self.current
      today = Date.today
      Week.new today.cwyear, today.cweek
    end

    # Public: Instantiate a Week for the prior week
    #
    # Returns an instance of Week
    def self.prior
      current.previous
    end

    # Public: A list of the last N weeks, excluding the current week
    #
    # count - An integer listing the number of weeks to return
    #
    # Returns an Array of Week instances
    def self.last count
      # holy hell this is gnarly
      #
      # essentially, create an array with the current week in it, then loop
      # through and tack on the previous week for whichever week is last; this
      # way, we keep tacking on ever more previous weeks as many times as is
      # asked for.
      out = [prior]
      (count - 1).times do
        out << out.last.previous
      end
      out
    end

    # Public: Friendly string representation of the week
    #
    # Returns a String of the start date
    def to_s
      start_date.strftime(DATE_STRING_FORMAT)
    end

    # Public: Programmer-friendly representation of the week
    #
    # Returns a String containing object details
    def inspect
      "#<#{self.class} #{to_s} (year=#{year} number=#{number})>"
    end

    # Public: Whether the week is the same as another week
    #
    # Returns a Boolean
    def == other
      year == other.year && number == other.number
    rescue
      false
    end

    # Public: The previous week
    #
    # Returns an instance of Week
    def previous
      if number == 1
        # carry the 1
        Week.new year - 1, 52
      else
        Week.new year, number - 1
      end
    end

    # Public: The next week
    #
    # Returns an instance of Week
    def next
      if number == 52
        # carry the 1
        Week.new year + 1, 1
      else
        Week.new year, number + 1
      end
    end

    # Public: Monday that starts the week
    #
    # Returns an instance of Date
    def start_date
      Date.commercial year, number
    end

    # Public:  Sunday that ends the week
    #
    # Returns an instance of Date
    def end_date
      Date.commercial year, number, 7
    end

    InvalidType = Class.new(StandardError)
  end
end
