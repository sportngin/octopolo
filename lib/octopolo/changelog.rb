require 'fileutils'

module Automation
  class Changelog
    attr_reader :filename

    def initialize(filename="CHANGELOG.markdown")
      @filename = filename
    end

    def readlines
      File.readlines(@filename)
    end

    def open
      FileUtils.touch(@filename) unless File.exists?(@filename)
      File.copy_stream(@filename,'old_changelog')
      File.open('old_changelog', 'r') do |old_changelog|
        File.open(@filename, 'w') do |changelog|
          yield changelog
          old_changelog.each_line { |line| changelog.puts line }
        end
      end
      File.delete('old_changelog')
    end
  end
end
