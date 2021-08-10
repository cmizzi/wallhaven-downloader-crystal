module Wallhaven::Downloader
  class RateLimiter
    @history = [] of Int64

    def initialize(@count : UInt64, @rate : Time::Span)
      #
    end

    def should_wait?
      @history = @history.reject { |v| (Time.unix(v) + @rate).to_unix < Time.utc.to_unix }

      if @history.size >= @count
        return true
      end

      # Append a new entry.
      @history.push Time.utc.to_unix

      return false
    end
  end
end
