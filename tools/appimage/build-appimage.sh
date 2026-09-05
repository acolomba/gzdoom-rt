#!/usr/bin/env bash
# Build a self-contained GZDoom RT AppImage from a Linux checkout.
set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
cd "$repo_root"

version="${1:-dev}"
asset_dir="${GZDOOM_RT_ASSET_DIR:?Set GZDOOM_RT_ASSET_DIR to the release rt/ directory.}"
dlss_sdk_dir="${GZDOOM_RT_DLSS_SDK_DIR:-}"
build_root="$repo_root/build/appimage"
app_dir="$repo_root/AppDir"
dist_dir="$repo_root/dist"

if command -v brew >/dev/null; then
    brew_prefix="$(brew --prefix)"
    export CMAKE_PREFIX_PATH="$brew_prefix${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"
    export PKG_CONFIG_PATH="$brew_prefix/lib/pkgconfig:$brew_prefix/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
fi
x11_cxx_flags="$(pkg-config --cflags x11 2>/dev/null || true)"
if command -v brew >/dev/null && [[ -d "$(brew --prefix xorgproto 2>/dev/null)/include" ]]; then
    x11_cxx_flags="$x11_cxx_flags -isystem $(brew --prefix xorgproto)/include"
fi
shader_compiler="$(command -v glslc || true)"
if [[ -z "$shader_compiler" ]] && command -v brew >/dev/null; then
    shader_compiler="$(brew --prefix shaderc 2>/dev/null)/bin/glslc"
fi
[[ -x "$shader_compiler" ]] || { echo "glslc is required to build the RT shader." >&2; exit 1; }

require_path() {
    [[ -e "$1" ]] || { echo "Missing required input: $1" >&2; exit 1; }
}

require_path "$asset_dir/data/textures.json"
require_path "$asset_dir/wad"
require_path "$asset_dir/shaders"
require_path "$asset_dir/BlueNoise_LDR_RGBA_128.ktx2"
require_path "$asset_dir/WaterNormal_n.ktx2"

rm -rf "$build_root" "$app_dir" "$dist_dir"
mkdir -p "$build_root" "$app_dir" "$dist_dir"

# Build the shared libraries first, then copy their Linux shared objects into
# the image alongside the executable/runtime data.
cmake -S libraries/ZMusic -B "$build_root/zmusic" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release -DZMUSIC_INSTALL=OFF
cmake --build "$build_root/zmusic" --parallel

rtgl_options=(
    -DCMAKE_BUILD_TYPE=Release
    -DRG_WITH_SURFACE_XLIB=ON
    -DRG_WITH_SURFACE_WAYLAND=OFF
    -DRG_WITH_DX12=OFF
    -DRG_WITH_IMGUI=OFF
    -DRG_WITH_EXAMPLES=OFF
    "-DCMAKE_CXX_FLAGS=$x11_cxx_flags"
)
if [[ -n "$dlss_sdk_dir" ]]; then
    require_path "$dlss_sdk_dir/include/nvsdk_ngx.h"
    export DLSS_SDK_PATH="$dlss_sdk_dir"
    rtgl_options+=(-DRG_WITH_NATIVE_DLSS=ON)
else
    rtgl_options+=(-DRG_WITH_NATIVE_DLSS=OFF)
fi
# RTGL needs C++23 std::expected. GCC's libstdc++ provides it on the supported
# Linux builders, while the game itself is built with the caller-selected
# compiler (Clang in CI, due to an asmjit/GCC incompatibility there).
RTGL_CC="${RTGL_CC:-gcc}" RTGL_CXX="${RTGL_CXX:-g++}"
CC="$RTGL_CC" CXX="$RTGL_CXX" cmake -S libraries/RTGL -B "$build_root/rtgl" -G Ninja "${rtgl_options[@]}"
cmake --build "$build_root/rtgl" --parallel

export RTGL1_SDK_PATH="$repo_root/libraries/RTGL"
cmake -S . -B "$build_root/game" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DHAVE_RT=ON \
    -DPK3_QUIET_ZIPDIR=ON \
    -DZMUSIC_INCLUDE_DIR="$repo_root/libraries/ZMusic/include" \
    -DZMUSIC_LIBRARIES="$build_root/zmusic/source/libzmusic.so" \
    -DCMAKE_BUILD_RPATH='$ORIGIN' \
    -DINSTALL_RPATH='$ORIGIN'
cmake --build "$build_root/game" --parallel

cp "$build_root/game/gzdoom" "$app_dir/"
cp "$build_root/game/"*.pk3 "$app_dir/"
cp -a "$build_root/game/soundfonts" "$build_root/game/fm_banks" "$app_dir/"
cp -a "$build_root/zmusic/source/libzmusic.so"* "$app_dir/"
cp -a "$asset_dir" "$app_dir/rt"
mkdir -p "$app_dir/rt/bin"
cp "$build_root/rtgl/libRTGL1.so" "$app_dir/rt/bin/"

# A rebuilt renderer requires matching shaders. Overlay changed shaders onto
# the release shader pack instead of replacing that pack.
mkdir -p "$build_root/shaders"
"$shader_compiler" --target-env=vulkan1.2 -I libraries/RTGL/Source/Generated \
    libraries/RTGL/Source/Shaders/Fluid_Visualize.frag \
    -o "$build_root/shaders/Fluid_Visualize.frag.spv"
cp -a "$build_root/shaders/." "$app_dir/rt/shaders/"
if [[ -n "$dlss_sdk_dir" ]]; then
    find "$dlss_sdk_dir" -type f -name 'libnvidia-ngx-dlss.so*' -exec cp -a {} "$app_dir/rt/bin/" \;
fi

icon_dir="$app_dir/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$icon_dir"
convert src/win32/icon1.ico[0] -flatten -resize 256x256 "$icon_dir/game_icon.png"
appimage-builder --skip-tests
image="$(find . -maxdepth 1 -type f -name '*.AppImage' -print -quit)"
[[ -n "$image" ]] || { echo "appimage-builder did not produce an AppImage." >&2; exit 1; }
mv "$image" "$dist_dir/gzdoom-rt-${version}-x86_64.AppImage"
