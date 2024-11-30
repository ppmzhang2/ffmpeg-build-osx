#!/usr/bin/env bash

DST=$PWD/build
SRC="$PWD/contrib"
DIR_BUILD_CONTRIB="$PWD/build_contrib"
N_CORE=$(sysctl -n hw.ncpu)

mkdir -p "${DST}"
mkdir -p "${DIR_BUILD_CONTRIB}"

# Dictionary mapping package names to their check files
declare -A PKG_CKFILES=(
    [fribidi]="lib/pkgconfig/fribidi.pc"
    [yasm]="lib/libyasm.a"
    [nasm]="bin/nasm"
    [zlib]="lib/pkgconfig/zlib.pc"
    [lame]="lib/libmp3lame.a"
    [x264]="lib/pkgconfig/x264.pc"
    [vpx]="lib/pkgconfig/vpx.pc"
    [expat]="lib/pkgconfig/expat.pc"
    [iconv]="lib/libiconv.a"
    [enca]="lib/pkgconfig/enca.pc"
    [freetype]="lib/pkgconfig/freetype2.pc"
    [gettext]="lib/libintl.a"
    [fontconfig]="lib/pkgconfig/fontconfig.pc"
    [ass]="lib/pkgconfig/libass.pc"
    [opus]="lib/pkgconfig/opus.pc"
    [ogg]="lib/pkgconfig/ogg.pc"
    [vorbis]="lib/pkgconfig/vorbis.pc"
    [theora]="lib/pkgconfig/theora.pc"
    [aom]="lib/pkgconfig/aom.pc"
    [x265]="lib/pkgconfig/x265.pc"
    [harfbuzz]="lib/pkgconfig/harfbuzz.pc"
    [vidstab]="lib/pkgconfig/vidstab.pc"
    [snappy]="lib/libsnappy.a"
)

# Unified function for ./configure-based builds
function compile_config() {
    local name=$1                   # Dependency name
    local path=$2                   # Source directory path
    local -a config_opts=("${@:3}") # Additional options as an array (rest of arguments)

    # Check if the package is already compiled and installed
    local check_file="${PKG_CKFILES[$name]}"
    if [[ -e "${DST}/${check_file}" ]]; then
        echo "📦 ${name} is already compiled and installed"
        return
    fi

    # Configure the package
    cd "${path}" || exit
    make clean
    local cfg_opts_str="${config_opts[*]}"
    export CFLAGS="-I${DST}/include ${CFLAGS}"
    export CPPFLAGS="-I${DST}/include ${CPPFLAGS}"
    export CXFLAGS="-I${DST}/include ${CXFLAGS}"
    export LDFLAGS="-L${DST}/lib ${LDFLAGS}"
    export PKG_CONFIG_PATH="${DST}/lib/pkgconfig:${PKG_CONFIG_PATH}"
    echo "♻️  Start compiling ${name} with options: ${cfg_opts_str}"
    ./configure --prefix="${DST}" "${config_opts[@]}"

    # Compile and install the package
    echo "🚀 Start building ${name}"
    make -j "${N_CORE}"
    make install

    # Post-installation check
    if [[ -e "${DST}/${check_file}" ]]; then
        echo "✅ ${name} is successfully compiled and installed"
        return
    else
        echo "❌ ${name} failed to compile"
        exit 1
    fi
}

# Individual build functions using the unified function
function build_fribidi() {
    compile_config "fribidi" \
        "${SRC}/fribidi" \
        "--disable-debug" \
        "--disable-dependency-tracking" \
        "--disable-silent-rules" \
        "--disable-shared" \
        "--enable-static"
}

function build_yasm() {
    compile_config "yasm" "${SRC}/yasm"
}

function build_nasm() {
    compile_config "nasm" "${SRC}/nasm"
}

function build_zlib() {
    compile_config "zlib" \
        "${SRC}/zlib" \
        "--static"
}

function build_lame() {
    compile_config "lame" \
        "${SRC}/lame" \
        "--disable-shared" \
        "--enable-static"
}

function build_x264() {
    compile_config "x264" \
        "${SRC}/x264" \
        "--enable-static" \
        "--enable-pic"
}

function build_vpx() {
    compile_config "vpx" \
        "${SRC}/libvpx" \
        "--enable-vp8" \
        "--enable-postproc" \
        "--enable-vp9-postproc" \
        "--enable-vp9-highbitdepth" \
        "--disable-examples" \
        "--disable-docs" \
        "--enable-multi-res-encoding" \
        "--disable-unit-tests" \
        "--enable-pic" \
        "--disable-shared"
}

function build_expat() {
    compile_config "expat" \
        "${SRC}/expat" \
        "--disable-shared" \
        "--enable-static"
}

function build_iconv() {
    compile_config "iconv" \
        "${SRC}/iconv" \
        "--disable-shared" \
        "--enable-static"
}

function build_enca() {
    export LIBS="-liconv"
    compile_config "enca" \
        "${SRC}/enca" \
        "--disable-dependency-tracking" \
        "--disable-shared" \
        "--enable-static"
}

function build_freetype() {
    compile_config "freetype" \
        "${SRC}/freetype" \
        "--disable-shared" \
        "--enable-static"
}

function build_gettext() {
    compile_config "gettext" \
        "${SRC}/gettext" \
        "--disable-dependency-tracking" \
        "--disable-silent-rules" \
        "--disable-debug" \
        "--disable-shared" \
        "--enable-static" \
        "--with-included-gettext" \
        "--with-included-glib" \
        "--with-included-libcroco" \
        "--with-included-libunistring" \
        "--with-emacs" \
        "--disable-java" \
        "--disable-csharp" \
        "--without-git" \
        "--without-cvs" \
        "--without-xz"
}

function build_fontconfig() {
    export FREETYPE_CFLAGS="-I${DST}/include/freetype2"
    export FREETYPE_LIBS="-L${DST}/lib -lfreetype"

    compile_config "fontconfig" \
        "${SRC}/fontconfig" \
        "--enable-iconv" \
        "--disable-libxml2" \
        "--disable-shared" \
        "--enable-static" \
        "--disable-docs"
}

function build_ass() {
    export LD=$LD64

    compile_config "ass" \
        "${SRC}/ass" \
        "--disable-dependency-tracking" \
        "--disable-shared" \
        "--enable-static"
}

function build_opus() {
    compile_config "opus" \
        "${SRC}/opus" \
        "--disable-shared" \
        "--enable-static"
}

function build_ogg() {

    # No need as ogg has fixed it
    # echo "🔨 Applying patch for ogg"
    # cd "${SRC}/ogg" || exit
    # patch -p1 <./fix_unsigned_typedefs.patch

    compile_config "ogg" \
        "${SRC}/ogg" \
        "--disable-shared" \
        "--enable-static" \
        "--build=aarch64-apple-darwin"
}

function build_vorbis() {
    export CFLAGS="-O3 -ffast-math -fsigned-char ${CFLAGS}"
    export LDFLAGS="-L${DST}/lib ${LDFLAGS}"

    echo "🔨 Applying patch for vorbis"
    cp "$DST/../fix_powerpc_option.patch" "${SRC}/vorbis"
    cd "${SRC}/vorbis" || exit
    patch -p1 <./fix_powerpc_option.patch # patch configure.ac
    rm -f configure && autoreconf -fiv    # regenerate configure script

    compile_config "vorbis" \
        "${SRC}/vorbis" \
        "--with-ogg-libraries=${DST}/lib" \
        "--with-ogg-includes=${DST}/include" \
        "--enable-static" \
        "--disable-shared" \
        "--host=aarch64-apple-darwin" \
        "--build=aarch64-apple-darwin"
}

function build_theora() {
    compile_config "theora" \
        "${SRC}/theora" \
        "--disable-asm" \
        "--with-ogg-libraries=${DST}/lib" \
        "--with-ogg-includes=${DST}/include" \
        "--with-vorbis-libraries=${DST}/lib" \
        "--with-vorbis-includes=${DST}/include" \
        "--enable-static" \
        "--disable-shared"
}

# CMake-based dependencies
function build_aom() {
    if [[ -e "${DST}/${PKG_CKFILES[aom]}" ]]; then
        echo "📦: AOM is already compiled and installed"
        return
    fi
    echo '♻️  Starting compilation of AOM...'

    # Create the build directories
    BUILD_DIR="${DIR_BUILD_CONTRIB}/aom_build"
    rm -rf "${BUILD_DIR}" && mkdir -p "${BUILD_DIR}"

    # Define CMake parameters
    AOM_CMAKE_PARAMS=(
        -DENABLE_DOCS=off
        -DENABLE_EXAMPLES=off
        -DENABLE_TESTDATA=off
        -DENABLE_TESTS=off
        -DENABLE_TOOLS=off
        -DCMAKE_INSTALL_PREFIX="${DST}"
        -DLIBTYPE=STATIC
        -DCONFIG_RUNTIME_CPU_DETECT=0
    )

    cmake -S "${SRC}/aom" -B "${BUILD_DIR}" "${AOM_CMAKE_PARAMS[@]}"
    cmake --build "${BUILD_DIR}" --target install -- -j "${N_CORE}"
}

function build_x265() {
    if [[ -e "${DST}/${PKG_CKFILES[x265]}" ]]; then
        echo "📦: x265 is already compiled and installed"
        return
    fi
    echo '♻️  Starting compilation of X265...'
    export CFLAGS="-I${DST}/include ${CFLAGS}"
    export CPPFLAGS="-I${DST}/include ${CPPFLAGS}"
    export CXFLAGS="-I${DST}/include ${CXFLAGS}"
    export LDFLAGS="-L${DST}/lib ${LDFLAGS}"
    export PKG_CONFIG_PATH="${DST}/lib/pkgconfig:${PKG_CONFIG_PATH}"

    # Define paths
    BUILD_DIR="${DIR_BUILD_CONTRIB}/x265_build"
    DIR_TMP="${DIR_BUILD_CONTRIB}/x265_intermediate"

    # Clean previous builds
    rm -rf "${BUILD_DIR}" "${DIR_TMP}"
    mkdir -p "${BUILD_DIR}"
    mkdir -p "${DIR_TMP}"

    # Build X265 12bit
    echo '♻️  Building X265 12bit...'
    X265_12BIT_CMAKE_PARAMS=(
        -DCMAKE_INSTALL_PREFIX="${DIR_TMP}"
        -DHIGH_BIT_DEPTH=ON
        -DMAIN12=ON
        -DENABLE_SHARED=NO
        -DEXPORT_C_API=NO
        -DENABLE_CLI=OFF
    )
    cmake -S "${SRC}/x265/source" -B "${BUILD_DIR}" "${X265_12BIT_CMAKE_PARAMS[@]}"
    cmake --build "${BUILD_DIR}" -- -j "${N_CORE}"
    mv "${BUILD_DIR}/libx265.a" "${DIR_TMP}/libx265_main12.a"

    # Clean and reset the build directory
    rm -rf "${BUILD_DIR}" && mkdir -p "${BUILD_DIR}"

    # Build X265 10bit
    echo '♻️  Building X265 10bit...'
    X265_10BIT_CMAKE_PARAMS=(
        -DCMAKE_INSTALL_PREFIX="${DIR_TMP}"
        -DHIGH_BIT_DEPTH=ON
        -DMAIN10=ON
        -DENABLE_SHARED=NO
        -DEXPORT_C_API=NO
        -DENABLE_CLI=OFF
    )
    cmake -S "${SRC}/x265/source" -B "${BUILD_DIR}" "${X265_10BIT_CMAKE_PARAMS[@]}"
    cmake --build "${BUILD_DIR}" -- -j "${N_CORE}"
    mv "${BUILD_DIR}/libx265.a" "${DIR_TMP}/libx265_main10.a"

    # Clean and reset the build directory
    rm -rf "${BUILD_DIR}" && mkdir -p "${BUILD_DIR}"

    # Build X265 full
    echo '♻️  Building X265 full...'
    X265_FULL_CMAKE_PARAMS=(
        -DCMAKE_INSTALL_PREFIX="${DST}"
        -DEXTRA_LIB="${DIR_TMP}/libx265_main10.a;${DIR_TMP}/libx265_main12.a"
        -DEXTRA_LINK_FLAGS=-L"${DIR_TMP}"
        -DLINKED_12BIT=ON
        -DLINKED_10BIT=ON
        -DENABLE_SHARED=OFF
        -DENABLE_CLI=OFF
    )
    cmake -S "${SRC}/x265/source" -B "${BUILD_DIR}" "${X265_FULL_CMAKE_PARAMS[@]}"
    cmake --build "${BUILD_DIR}" -- -j "${N_CORE}"
    mv "${BUILD_DIR}/libx265.a" "${DST}/lib/libx265_main.a"

    # Combine libraries into a single static library
    echo '♻️  Combining X265 libraries...'
    libtool -static -o "${DST}/lib/libx265.a" \
        "${DST}/lib/libx265_main.a" \
        "${DIR_TMP}/libx265_main10.a" \
        "${DIR_TMP}/libx265_main12.a" 2>/dev/null

    # # Install and copy artifacts
    cp "${BUILD_DIR}/x265.pc" "${DST}/lib/pkgconfig/"
    cp "${BUILD_DIR}/x265_config.h" "${DST}/include/"
    cp "${SRC}/x265/source/x265.h" "${DST}/include/"

    echo "✅ X265 compiled and installed successfully."
}

function build_harfbuzz() {
    if [[ -e "${DST}/${PKG_CKFILES[harfbuzz]}" ]]; then
        echo "📦: HarfBuzz is already compiled and installed"
        return
    fi
    echo '♻️  Starting compilation of HarfBuzz...'

    # Create the build directories
    BUILD_DIR="${DIR_BUILD_CONTRIB}/harfbuzz_build"
    rm -rf "${BUILD_DIR}" && mkdir -p "${BUILD_DIR}"

    # Define CMake parameters
    CMAKE_PARAMS=(
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX="${DST}"
        -DBUILD_SHARED_LIBS=OFF
        -DHARFBUZZ_BUILD_TESTS=OFF
        -DHARFBUZZ_BUILD_UTILS=OFF
    )

    cmake -S "${SRC}/harfbuzz" -B "${BUILD_DIR}" "${CMAKE_PARAMS[@]}"
    cmake --build "${BUILD_DIR}" --target install -- -j "${N_CORE}"
}

function build_vidstab() {
    if [[ -e "${DST}/${PKG_CKFILES[vidstab]}" ]]; then
        echo "📦: Vid-stab is already compiled and installed"
        return
    fi

    # Apply patch to fix CMake quoting
    echo "🔨 Applying patch for vidstab"
    cd "${SRC}/vidstab" || exit
    patch -p1 <fix_cmake_quoting.patch

    # Create the build directories
    echo '♻️ ' Start compiling Vid-stab
    BUILD_DIR="${DIR_BUILD_CONTRIB}/vidstab_build"
    rm -rf "${BUILD_DIR}" && mkdir -p "${BUILD_DIR}"

    CMAKE_PARAMS=(
        -DCMAKE_INSTALL_PREFIX:PATH="${DST}"
        -DLIBTYPE=STATIC
        -DBUILD_SHARED_LIBS=OFF
        -DENABLE_SHARED_LIBS=OFF
        -DENABLE_SHARED=OFF
        -DUSE_OMP=OFF
    )

    cmake -S . -B "${BUILD_DIR}" "${CMAKE_PARAMS[@]}"
    cmake --build "${BUILD_DIR}" --target install -- -j "${N_CORE}"
}

function build_snappy() {
    if [[ -e "${DST}/${PKG_CKFILES[snappy]}" ]]; then
        echo "📦: Snappy is already compiled and installed"
        return
    fi

    echo '♻️ ' Start compiling Snappy

    # Create the build directories
    BUILD_DIR="${DIR_BUILD_CONTRIB}/snappy_build"
    rm -rf "${BUILD_DIR}" && mkdir -p "${BUILD_DIR}"

    CMAKE_PARAMS=(
        -DCMAKE_INSTALL_PREFIX:PATH="${DST}"
        -DLIBTYPE=STATIC
        -DSNAPPY_BUILD_TESTS=OFF
        -DSNAPPY_BUILD_BENCHMARKS=OFF
        -DENABLE_SHARED=OFF
    )

    cmake -S "${SRC}/snappy" -B "${BUILD_DIR}" "${CMAKE_PARAMS[@]}"
    cmake --build "${BUILD_DIR}" --target install -- -j "${N_CORE}"
}

# Build ./configure-based dependencies
build_fribidi
build_yasm
build_aom
build_nasm
build_zlib
build_lame
build_x264
build_x265
build_vpx
build_expat
build_iconv
build_enca
build_freetype
build_gettext
build_fontconfig
build_harfbuzz
build_ass
build_opus
build_ogg
build_vorbis
build_theora
build_vidstab
build_snappy
