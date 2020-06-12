module Octopolo
  class SemverTagScrubber

    def self.scrub_prefix(tag)
      scrub_via_regexp(tag, /\A[a-z]*/i)
    end

    def self.scrub_suffix(tag)
      scrub_via_regexp(tag, /[a-z]*\z/i)
    end

    private

    def self.scrub_via_regexp(tag, regexp)
      begin
        result = tag.match(regexp)[0]
        tag.gsub!(regexp, '')
        result
      rescue Exception => e
        if e.message.include?("match' for nil:NilClass")
          puts 'You are creating the first GitHub release for this repository.'
        else
          puts "Error finding existing GitHub release(s): #{e.message}"
        end
      end
    end

  end
end
