require "spec"
require "../src/rate-limiter.cr"

describe "Wallhaven::Downloader::RateLimiter" do
  it "can_rate_limit_something" do
    limiter = Wallhaven::Downloader::RateLimiter.new 1, 1.seconds

    limiter.should_wait?.should be_false
    limiter.should_wait?.should be_true

    sleep 1500.milliseconds
    limiter.should_wait?.should be_false
  end
end
