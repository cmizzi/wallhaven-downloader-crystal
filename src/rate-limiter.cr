module Wallhaven::Downloader
  class RateLimiter
    @history = [] of Int64

    def initialize(@count : UInt64, @rate : Time::Span)
      #
    end

    # Is there a spot available in the history ?
    def should_wait?
      # Reject every history element that is passed in time (from now).
      @history = @history.reject { |v| (Time.unix(v) + @rate).to_unix < Time.utc.to_unix }

      # While the history doesn't have reached the maximum allowed, return true.
      return true unless @history.size < @count

      # Append a new entry.
      @history.push Time.utc.to_unix
      false
    end

    # Wait until the limiter is free.
    def wait
      while self.should_wait?
        # Define the rate limit. If the timer is not reached, we cannot do any request, we just have to wait.
        sleep 100.milliseconds
      end
    end
  end
end
