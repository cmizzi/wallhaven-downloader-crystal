# Wallhaven downloader

Wallhaven downloader is a simple and useful utility to automatically download wallpapers from
[Wallhaven](https://wallhaven.cc/).

## Installation

```bash
# Build from source
git clone git@github.com:cmizzi/wallhaven-downloader-crystal
cd wallhaven-downloader-crystal
shards build

# Copy the binary to make it user-available
sudo cp bin/wallhaven-downloader /usr/local/bin/wallhaven-downloader
```

## Usage

```bash
Usage:
  wallhaven-downloader [flags...] <output> [arg...]

Show this help.

Flags:
  --categories, -c (default: "111")
  --direction, -d (default: "desc")
  --help
  --limit, -l (default: 10)
  --purity, -p (default: "100")
  --resolutions, -r (default: ["1920x1080"])
  --sorting, -s (default: "random")
  --version

Arguments:
  output (required)
```

## Contributing

1. Fork it (<https://github.com/cmizzi/wallhaven-downloader-crystal/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Cyril Mizzi](https://github.com/cmizzi) - creator and maintainer
