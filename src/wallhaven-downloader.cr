require "http/client"
require "log"
require "admiral"
require "crystagiri"

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
    @next_request_at : Int64 = Time.utc.to_unix

    def run
      page = 1u32
      wallpapers = [] of String

      loop do
        # Start fetching the first page and count the number of wallpapers in there.
        response = self.request(URI.new "https", "wallhaven.cc", path: "/search", query: URI::Params.encode self.build_query_params(page))

        parser = Crystagiri::HTML.new response.body
        parser.css("a.preview") do |tag|
          # Check first we have enough wallpapers. If we have enough, we don't need to parse every other wallpapers.
          next if wallpapers.size >= flags.limit

          # Fetch the wallpaper.
          wallpaper_response = self.request tag.node.attributes["href"].content
          wallpaper_parser = Crystagiri::HTML.new wallpaper_response.body

          wallpaper = wallpaper_parser.at_id("wallpaper").not_nil!.node.attributes["src"].content
          wallpaper_name = Path.posix(wallpaper).basename

          # The wallpaper already exist. Let's skip it.
          if File.exists?(Path.new(arguments.output, wallpaper_name))
            puts "Oops, the wallpaper \"#{wallpaper_name}\" already exists. Skip it."
            next
          end

          wallpapers.push wallpaper
        end

        # Filter out any duplicate.
        wallpapers = wallpapers.uniq()

        page = page + 1
        break if wallpapers.size >= flags.limit
      end

      wallpapers = wallpapers[0..flags.limit - 1]

      # Now, we can loop on every wallpapers and ensure we download them into the right directory.
      wallpapers.each do |wallpaper|
        response = self.request wallpaper

        File.write(Path.new(arguments.output, Path.posix(wallpaper).basename), response.body)
        Log.info { "Wallpaper \"#{Path.posix(wallpaper).basename}\" has been downloaded successfully." }
      end
    end

    # Build the query params for the search query.
    def build_query_params(page : UInt32)
      return {
        "categories": flags.categories,
        "purity": flags.purity,
        "atleast": flags.resolutions,
        "sorting": flags.sorting,
        "direction": flags.direction,
        "seed": @seed,
        "page": "#{page}"
      }
    end

    # Execute a request to an HTTP endpoint.
    def request(uri : URI)
      loop do
        # Define the rate limit. If the timer is not reached, we cannot do any request, we just have to wait.
        if @next_request_at > Time.utc.to_unix
          sleep 100.milliseconds
          next
        end

        break
      end

      response = HTTP::Client.get(uri)
      @next_request_at = Time.utc.shift(seconds: 2).to_unix

      Log.debug { "#{uri} (#{response.status_code})" }

      if response.status_code != 200
        raise "Oops, Wallhaven returned a status code \"#{response.status_code}\"."
      end

      return response
    end

    def request(uri : String)
      return self.request URI.parse uri
    end
  end
end

Wallhaven::Downloader::Downloader.run
