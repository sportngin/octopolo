require "csv"

module Automation
  module Reports
    # Public: Write the report data to the given file name
    #
    # data - Array of report data, each element being a line of the CSV
    # filename - The name of the file to write to
    def self.write_csv data, filename
      CSV.open filename, "w" do |file|
        data.each do |line|
          file.puts line
        end
      end
    end
  end
end

