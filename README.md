# GZDoom: Ray Traced

**GZDoom: Ray Traced** introduces a path tracing renderer to **GZDoom**, a Doom source port.


## Local Build

### Windows

1. Run `auto-setup-windows.cmd` to configure and build via CMake
    * This will produce `build/RelWithDebInfo/gzdoom.exe` (and Visual Studio solution `build/GZDoom.sln`)
1. Copy from a release package into `build/RelWithDebInfo/` folder:
    1. `rt` folder
    1. `libsndfile-1.dll`
    1. `openal32.dll`
    1. `zmusic.dll`
1. Run `build/RelWithDebInfo/gzdoom.exe`

### Linux

Native Linux (no Wine/Proton), with the RTGL1 path tracer and NVIDIA DLSS.

**Prebuilt AppImage** — the quickest way to run it. Download the AppImage from
the [latest release](../../releases/latest), make it executable, and run it:

```sh
chmod +x gzdoom-rt-*-x86_64.AppImage
./gzdoom-rt-*-x86_64.AppImage
```

GZDoom auto-detects IWADs from Steam, GOG, and the usual locations; if yours are
elsewhere, point it at them with `DOOMWADDIR=/path/to/wads` or `-iwad`. Requires
an NVIDIA GPU with a current driver and Vulkan.

**Build from source** — the game, ZMusic, and the RTGL1 renderer are built
separately, then combined with an RT asset pack. See
[docs/APPIMAGE_RELEASE.md](docs/APPIMAGE_RELEASE.md) for the self-contained
AppImage build (and the CI that produces the release).

##

Licensed under the [GNU General Public License Version 3](LICENSE).
Copyright (c) 1998-2023 ZDoom + GZDoom teams, and contributors.
Doom Source (c) 1997 id Software, Raven Software, and contributors.
Please see license files for individual contributor licenses.

---

[Home Page](https://zdoom.org/) |
[Forum](https://forum.zdoom.org/) |
[Wiki](https://zdoom.org/wiki/) |
[Discord Server](https://dsc.gg/zdoom) |
[Translation sheet (Google Docs)](https://docs.google.com/spreadsheets/d/1pvwXEgytkor9SClCiDn4j5AH7FedyXS-ocCbsuQIXDU/edit?usp=sharing)
