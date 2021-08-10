require "http/client"
require "log"
require "admiral"
require "crystagiri"
require "./rate-limiter"

Log.setup("", :debug)

module Wallhaven::Downloader
  VERSION = "0.1.0"

  class Downloader < Admiral::Command
    define_version "#{VERSION}"
    define_help description: "Show this help."
    define_flag limit : UInt32, default: 10u32, short: l
    define_flag categories : String, default: "111", short: c
    define_flag purity : String, default: "100", short: p
    define_flag resolutions : Array(String), default: ["1920x1080"], short: r
    define_flag sorting : String, default: "random", short: s
    define_flag direction : String, default: "desc", short: d
    define_argument output : String, required: true

    # Static seed to use for every search request.
    @seed = Random::Secure.urlsafe_base64(5)

    # Really simple rate limiter. This will just allow us to send only 1 req/s to prevent being 429.
    @rate_limiter = RateLimiter.new 1, 1.second

    # Main command loop.
    def run
      page = 1u32
      wallpapers = [] of String

      until wallpapers.size >= flags.limit
        # Start fetching the first page and count the number of wallpapers in there.
        parser = self.request_and_parse(URI.new "https", "wallhaven.cc", path: "/search", query: URI::Params.encode self.build_query_params(page))
        parser.css("a.preview") do |tag|
          # Check first we have enough wallpapers. If we have enough, we don't need to parse every other wallpapers.
          next if wallpapers.size >= flags.limit

          # Fetch the wallpaper and parse the HTML.
          parser = self.request_and_parse tag.node.attributes["href"].content

          # We know the original wallpaper is stored at #wallpaper id.
          wallpaper = parser.at_id("wallpaper").not_nil!.node.attributes["src"].content
          wallpaper_name = Path.posix(wallpaper).basename

          # The wallpaper already exist. Let's skip it.
          if File.exists?(Path.new(arguments.output, wallpaper_name))
            Log.info { "Oops, the wallpaper \"#{wallpaper_name}\" already exists. Skip it." }
            next
          end

          # Push the current wallpaper (detail URL) into the array.
          wallpapers.push wallpaper
        end

        # Filter out any duplicate.
        wallpapers = wallpapers.uniq
        page = page + 1
      end

      # Now, we can loop on every wallpapers and ensure we download them into the right directory.
      wallpapers.each do |wallpaper|
        File.write(Path.new(arguments.output, Path.posix(wallpaper).basename), self.request(wallpaper).body)
        Log.info { "Wallpaper \"#{Path.posix(wallpaper).basename}\" has been downloaded successfully." }
      end
    end

    # Build the query params for the search query.
    def build_query_params(page : UInt32)
      return {
        "categories": flags.categories,
        "purity":     flags.purity,
        "atleast":    flags.resolutions,
        "sorting":    flags.sorting,
        "direction":  flags.direction,
        "seed":       @seed,
        "page":       "#{page}",
      }
    end

    # Execute a request to a HTTP endpoint (URI).
    def request(uri : URI)
      @rate_limiter.wait
      response = HTTP::Client.get(uri)

      Log.debug { "#{uri} (#{response.status_code})" }
      raise "Oops, Wallhaven returned a status code \"#{response.status_code}\"." if response.status_code != 200

      response
    end

    # Execute a request to a HTTP endpoint (string).
    def request(uri : String)
      self.request URI.parse uri
    end

    # Execute a request to a HTTP endpoint and parse the responded HTML.
    def request_and_parse(uri : URI | String)
      Crystagiri::HTML.new self.request(uri).body
    end
  end
end

Wallhaven::Downloader::Downloader.run
