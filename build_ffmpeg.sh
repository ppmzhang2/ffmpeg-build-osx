#!/usr/bin/env bash

BASE=$PWD
N_CORE=$(sysctl -n hw.ncpu)

# Set environment variables
export PATH="${SRC}/bin:$PATH"
export CFLAGS="-I$BASE/build/include $CFLAGS"
export CPPFLAGS="-I$BASE/build/include $CPPFLAGS"
export CXXFLAGS="-I$BASE/build/include $CXXFLAGS"
export LDFLAGS="-L$BASE/build/lib $LDFLAGS -lexpat -lenca -lfribidi -liconv -lstdc++ -lfreetype -framework CoreText -framework VideoToolbox"
export PKG_CONFIG_PATH="$BASE/build/lib/pkgconfig:$PKG_CONFIG_PATH"

cd "$BASE/ffmpeg" || exit
./configure \
    --prefix="$BASE/build" \
    --extra-cflags="-I$BASE/build/include -I$HOMEBREW_PREFIX/include" \
    --extra-ldflags="-L$BASE/build/lib -L$HOMEBREW_PREFIX/lib" \
    --pkg-config-flags=--static \
    --logfile=config.log \
    --arch=arm64 --cc="$CC" \
    --enable-fontconfig --enable-gpl --enable-libopus --enable-libtheora --enable-libvorbis \
    --enable-libmp3lame --enable-libass --enable-libfreetype --enable-libx264 --enable-libx265 --enable-libvpx \
    --enable-libaom --enable-libvidstab --enable-libsnappy --enable-version3 \
    --enable-ffplay --enable-postproc --enable-nonfree --enable-runtime-cpudetect

make -j "$N_CORE"
make install
