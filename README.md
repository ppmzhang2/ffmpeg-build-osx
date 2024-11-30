# Build FFmpeg for Apple Silicon

## Prerequisites

Install the following packages using Homebrew:

- `pkgconfig`
- `libtool`
- `glib`
- `autoconf`
- `automake`
- `cmake`

The `glib` will be linked dynamically because it is discouraged linking statically.

## Guide

- Clone this repository.

- Clone the repository and fetch submodules:

  ```bash
  git submodule update --depth 1 --recursive --init
  ```

- Fetch non-submodule dependencies.

  ```bash
  ./fetch_release.sh
  ```

- Build 3rd-party dependencies.

  ```bash
  ./build_contrib.sh
  ```

- Build FFmpeg.

  ```bash
  ./build_ffmpeg.sh
  ```

## References

- [FFmpeg for ARM-based Apple Silicon Macs](https://github.com/ssut/ffmpeg-on-apple-silicon)
