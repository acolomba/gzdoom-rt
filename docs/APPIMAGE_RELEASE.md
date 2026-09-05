# AppImage release

The AppImage workflow follows the existing Windows-release model: it compiles
the game from this checkout, then combines it with a separately published RT
asset pack. The final `gzdoom-rt-<tag>-x86_64.AppImage` is self-contained with
respect to the engine, PK3s, RT data, RTGL, and ordinary Linux user-space
libraries. Users still supply their own IWAD and a supported Vulkan/NVIDIA
driver.

Before running the workflow, configure these GitHub repository variables:

- `RT_ASSETS_URL` — HTTPS URL for a zip or tar archive containing the release
  `rt/` directory (`rt/data/textures.json` and the normal RT asset tree). The
  upstream gzdoom-rt release zip works directly, so nothing needs rehosting:
  `https://github.com/vs-shirokii/gzdoom-rt/releases/download/rt-1.0.2/gzdoom-rt-1.0.2.zip`
- `RT_ASSETS_SHA256` — strongly recommended SHA-256 for that archive.
- `DLSS_SDK_URL` and `DLSS_SDK_SHA256` — optional SDK archive and checksum.
  Supplying them enables native DLSS and copies its Linux feature library into
  `rt/bin/`. Without them the image builds and runs, but native DLSS is off.

Publishing a GitHub Release triggers the workflow. It uploads the AppImage to
that same release after the artifact is built. Push and pull-request runs keep
the resulting AppImage as a normal GitHub Actions artifact.

For a local build, install the dependencies named by
`.github/workflows/appimage.yml`, point `GZDOOM_RT_ASSET_DIR` at an extracted
`rt/` directory, then run:

```sh
CC=clang CXX=clang++ GZDOOM_RT_ASSET_DIR=/path/to/rt \
  tools/appimage/build-appimage.sh v1.0.0
```

The output is written to `dist/`. The staging directory is `AppDir/` and can be
inspected before it is packed.
