#!/usr/bin/env bash

# Define library directory
LIBDIR="$PWD/contrib"
TEMP_DIR="$PWD/temp"

mkdir -p "$LIBDIR"   # Ensure the directory exists
mkdir -p "$TEMP_DIR" # Temporary directory for downloads

# Define URLs
declare -A URLS=(
    [x265]="https://bitbucket.org/multicoreware/x265_git/downloads/x265_4.1.tar.gz"
    [fribidi]="https://github.com/fribidi/fribidi/releases/download/v1.0.16/fribidi-1.0.16.tar.xz"
    [vidstab]="https://github.com/georgmartius/vid.stab/archive/refs/tags/v1.1.1.tar.gz"
    [snappy]="https://github.com/google/snappy/archive/1.2.1.tar.gz"
    [enca]="https://dl.cihar.com/enca/enca-1.19.tar.gz"
    [iconv]="https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.17.tar.gz"
    [zlib]="https://zlib.net/zlib-1.3.1.tar.gz"
    [theora]="http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.bz2"
    [expat]="https://github.com/libexpat/libexpat/releases/download/R_2_6_4/expat-2.6.4.tar.gz"
    [freetype]="https://download.savannah.gnu.org/releases/freetype/freetype-2.13.3.tar.gz"
    [gettext]="https://ftp.gnu.org/gnu/gettext/gettext-0.22.tar.xz"
    [fontconfig]="https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.15.0.tar.gz"
    [ass]="https://github.com/libass/libass/releases/download/0.17.3/libass-0.17.3.tar.gz"
    [yasm]="http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz"
    [pkgcfg]="https://pkg-config.freedesktop.org/releases/pkg-config-0.29.2.tar.gz"
    [nasm]="https://www.nasm.us/pub/nasm/releasebuilds/2.16.03/nasm-2.16.03.tar.gz"
    [vorbis]="https://downloads.xiph.org/releases/vorbis/libvorbis-1.3.7.tar.gz"
    [opus]="https://archive.mozilla.org/pub/opus/opus-1.3.1.tar.gz"
    [harfbuzz]="https://github.com/harfbuzz/harfbuzz/releases/download/10.1.0/harfbuzz-10.1.0.tar.xz"
    [ogg]="https://downloads.xiph.org/releases/ogg/libogg-1.3.5.tar.gz"
)

# Patch URLs
URL_ogg_patch="https://github.com/xiph/ogg/commit/c8fca6b4a02d695b1ceea39b330d4406001c03ed.patch?full_index=1"
URL_vidstab_patch="https://raw.githubusercontent.com/Homebrew/formula-patches/5bf1a0e0cfe666ee410305cece9c9c755641bfdf/libvidstab/fix_cmake_quoting.patch"

# Function to download and validate a file
download_file() {
    local name=$1
    local url=$2
    local target="$TEMP_DIR/$name"

    echo "Downloading: $name"
    if ! curl -Ls -o "$target" "$url"; then
        echo "Error: Failed to download $name from $url" >&2
        return 1
    fi
    echo "Downloaded: $name to $target"
}

# Function to extract a file
extract_file() {
    local name=$1
    local filepath=$2
    local format=$3

    echo "Extracting: $name"
    local temp_extract_dir="$TEMP_DIR/${name}_extract" # Temporary directory for extraction
    mkdir -p "$temp_extract_dir"

    case "$format" in
        gz) tar zxf "$filepath" -C "$temp_extract_dir" ;;
        xz) tar Jxf "$filepath" -C "$temp_extract_dir" ;;
        bz2) tar jxf "$filepath" -C "$temp_extract_dir" ;;
        *)
            echo "Error: Unsupported format $format for $name" >&2
            return 1
            ;;
    esac

    # Identify the extracted folder (assumes a single folder is extracted)
    local extracted_folder
    extracted_folder=$(find "$temp_extract_dir" -mindepth 1 -maxdepth 1 -type d)
    if [[ -z "$extracted_folder" ]]; then
        echo "Error: Extraction failed for $name" >&2
        return 1
    fi

    # Move to LIBDIR with the customized folder name
    local target_folder="$LIBDIR/$name"
    mv "$extracted_folder" "$target_folder"
    echo "Extracted and moved $name to $target_folder"
}

# Process each URL
for name in "${!URLS[@]}"; do
    # Identify file extension for extraction
    case "${URLS[$name]}" in
        *.tar.gz) format="gz" ;;
        *.tar.xz) format="xz" ;;
        *.tar.bz2) format="bz2" ;;
        *) format="" ;;
    esac

    # Download and extract in parallel
    download_file "$name" "${URLS[$name]}" &&
        extract_file "$name" "$TEMP_DIR/$name" "$format" &
done

# Wait for all downloads and extractions to finish
wait

# Fetch patches
echo "Fetching patches..."
curl -s -o "$LIBDIR/ogg/fix_unsigned_typedefs.patch" "$URL_ogg_patch"
curl -s -o "$LIBDIR/vidstab/fix_cmake_quoting.patch" "$URL_vidstab_patch"

# Cleanup temporary files
rm -rf "$TEMP_DIR"

echo "All downloads, extractions, and patch fetching complete."
