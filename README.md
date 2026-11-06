<div align="center">

**🇬🇧 English** | [🇨🇳 简体中文](readme/README.zh-CN.md) | [🇪🇸 Español](readme/README.es.md) | [🇧🇷 Português](readme/README.pt-BR.md) | [🇩🇪 Deutsch](readme/README.de.md) | [🇫🇷 Français](readme/README.fr.md) | [🇯🇵 日本語](readme/README.ja.md) | [🇰🇷 한국어](readme/README.ko.md) | [🇷🇺 Русский](readme/README.ru.md) | [🇺🇦 Українська](readme/README.uk.md)

# PhonerLite for NixOS

<img src="docs/screenshot.png" width="420" alt="PhonerLite running through Wine">


**A free SIP softphone, packaged for Nix — running on Wine with every desktop-integration pitfall already solved.**

[![CI](https://img.shields.io/github/actions/workflow/status/varsoug/phonerlite-flake/ci.yml?style=flat-square&label=ci)](https://github.com/varsoug/phonerlite-flake/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/varsoug/phonerlite-flake?style=flat-square)](https://github.com/varsoug/phonerlite-flake/releases)
[![License](https://img.shields.io/github/license/varsoug/phonerlite-flake?style=flat-square)](LICENSE)
[![NixOS unstable](https://img.shields.io/badge/nixos-unstable-blue.svg?style=flat-square&logo=nixos)](https://nixos.org)
[![Wine](https://img.shields.io/badge/wine-wow64%2011.0-732727?style=flat-square&logo=wine)](https://www.winehq.org)

[**Quick start**](#-quick-start) ·
[Features](#-features) ·
[Install](#-installing) ·
[How it works](#-how-it-works) ·
[Tested on](#-tested-on)

</div>

---

[PhonerLite](https://www.phonerlite.de) is a free (freeware) SIP softphone for Windows. This
flake packages it for NixOS / Nix on Linux and runs it through Wine **the way it should run**:
native window decorations, antialiased fonts, sane DPI, a window that survives minimize.

If you just install `pkgs.wine` and run `wine PhonerLite.exe`, you will hit a wall within
minutes: *"Bad EXE format"*, pixelated fonts, WinXP-style window buttons, a window that never
comes back from minimize, and an app that always reopens minimized. This package fixes all of
that out of the box.

## 🚀 Quick start

```bash
nix run github:varsoug/phonerlite-flake
```

The first run builds the package (about a minute) and starts PhonerLite. SIP accounts, the
phone book and call logs live in `~/.local/share/phonerlite/` — the app stays fully portable.
The vendor's portable ZIP ships with the flake, so the build needs no network access.

## ✨ Features

|   |   |
|---|---|
| 🍷 **Wine, pre-tuned** | Dedicated 64-bit prefix, correct driver choice, registry and ini fixes applied automatically. |
| 🪟 **Native decorations** | KWin/GNOME draw the title bar — no built-in WinXP buttons. |
| 🔤 **Crisp fonts** | Full font smoothing (ClearType-equivalent) enabled in the prefix. |
| 🖼️ **Sane DPI** | Renders at 120 PPI by default so icons are not blocky; configurable. |
| 🗂️ **Isolated prefix** | Lives in `~/.local/share/phonerlite-prefix`; your `~/.wine` is never touched. |
| 📦 **Zero setup** | One module line or one `nix run` — no winecfg, no winetricks, no manual registry edits. |
| 🔌 **Portable state** | Accounts, phone book and logs stay in `~/.local/share/phonerlite/`, independent of the store. |

## 📦 Installing

### Option 1 — NixOS module (recommended)

**1.** Add the input to your system's `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # ...your other inputs...
    phonerlite.url = "github:varsoug/phonerlite-flake";
  };
```

**2.** Enable the module:

```nix
  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        # ...your other modules...
        inputs.phonerlite.nixosModules.default
        { programs.phonerlite.enable = true; }
      ];
    };
  };
```

**3.** Rebuild and launch:

```bash
sudo nixos-rebuild switch --flake /path/to/your/flake#myhost
phonerlite
```

Prefer it as a plain package? Same result:

```nix
{ environment.systemPackages = [ inputs.phonerlite.packages.x86_64-linux.phonerlite ]; }
```

### Option 2 — Overlay

```nix
nixpkgs.overlays = [ inputs.phonerlite.overlays.default ];
# then, anywhere in your config:
environment.systemPackages = with pkgs; [ phonerlite ];
```

### Option 3 — No flakes (legacy config)

```nix
# configuration.nix
let
  phonerlite-flake = builtins.getFlake "github:varsoug/phonerlite-flake";
in
{
  environment.systemPackages = [ phonerlite-flake.packages.x86_64-linux.phonerlite ];
}
```

> [!NOTE]
> No home-manager is required — the only flake input is `nixpkgs`.

## ⚙️ Configuration

The package adapts to the session at launch — there are no separate Wayland and X11 branches
or packages. The launcher looks at `XDG_SESSION_TYPE` (falling back to `WAYLAND_DISPLAY`) and:

| Session | What the launcher does |
| --- | --- |
| Wayland (Plasma, GNOME, sway…) | Runs PhonerLite through **XWayland** with `WAYLAND_DISPLAY` unset: Wine's own Wayland driver has no `xdg-decoration` support and its minimise bug breaks the window controls. |
| X11 | Runs PhonerLite directly; the window manager draws the frame. |
| Unknown (started from a systemd unit, cron…) | Guesses from `WAYLAND_DISPLAY`; force the right one with `sessionType`. |

Override the defaults when calling the package:

```nix
pkgs.callPackage ./packages/phonerlite.nix {
  scalePPI = "96";             # default "120"; PhonerLite targets 96 PPI
  sessionType = "x11";         # "auto" (default), "wayland" or "x11"
  trayMode = "tray";           # "taskbar" (default) or "tray"
}
```

`trayMode = "taskbar"` keeps the window in the task list, so it can always be raised and
closed. `trayMode = "tray"` sets `HideTaskbarIcon=1`: the app lives only in the system tray,
which is handy if your panel has a tray — and a dead end if it is hidden or covered.

## 🔍 How it works

<details>
<summary>The details behind every workaround</summary>

**Why a dedicated prefix.** `PhonerLite.exe` is a 64-bit PE binary. If your default `~/.wine`
is a 32-bit prefix, Wine refuses to run it with "Bad EXE format". The launcher keeps its own
prefix at `~/.local/share/phonerlite-prefix` and never touches `~/.wine`.

**Why `wineWow64Packages.stable`, not `.wayland`.** The `wayland` Wine build ships no X11
driver at all (`winex11.drv` is absent), so the app cannot start. `stable`, `staging` and
`full` all include both drivers.

**Why force the X11 driver (`env -u WAYLAND_DISPLAY`).** First, `winewayland.so` does not
implement the `xdg-decoration` protocol — it always draws its own WinXP-style title bar, and
the `Decorated=Y` registry key only affects the X11 driver. Second, the Wayland driver has a
bug where minimizing the window kills the window controls until restart. Through XWayland
both problems disappear and the compositor draws a normal title bar.

**Why the portable ZIP, not the installer.** The vendor ships a portable ZIP; the installer
only creates shortcuts. The ZIP is unpacked into the nix store, and the launcher copies it to
`~/.local/share/phonerlite` on first run and starts it from there — PhonerLite keeps
`sipper.ini`, its phone book and logs next to the `.exe`, while the store path stays read-only.

**Registry keys written on every launch** (idempotent):
- `HKCU\Control Panel\Desktop\Decorated=Y` — hand window decoration to the window manager;
- `FontSmoothing=2`, `FontSmoothingType=2`, `FontSmoothingOrientation=1`,
  `FontSmoothingGamma=0x578` — full font antialiasing (a fresh prefix renders pixelated text).
- `LogPixels` is deliberately **not** set: with it, PhonerLite hangs before creating its main
  window.

**Ini fixes applied on every launch** (idempotent): `WindowState=0` (otherwise the app opens
minimized — it saves that state on exit), `HideTaskbarIcon=0` (with `1` the app lives only in
the system tray, and a hidden or covered tray leaves no way to raise or quit it) and
`ScaleDefaultPPI=<scalePPI>` (UI scale).

**Window frames.** Before the app starts, the launcher writes `Decorated=Y` and stops any
wineserver left over from an earlier launch: the X11 driver reads that key when the server
starts, and a stale server keeps the old value, which shows up as a second WinXP-style frame
next to an incoming-call window. On a native X11 session the window manager draws the frame
itself, so the key is harmless there; it matters under XWayland, where Wine's own frame would
otherwise double the compositor's.

**Packing quirks.** Nix's own unpacker cannot open the vendor ZIP ("do not know how to
unpack source archive"), so `dontUnpack = true` and `installPhase` extracts it with `unzip`;
its non-zero exit on the ZIP's non-ASCII member names is ignored, and the per-language
license copies are dropped. The icon is extracted from the `.exe` resources with
`wrestool`/`icotool`.

**CI.** `.github/workflows/ci.yml` builds the package and checks its outputs (launcher,
desktop entry, icon) on every push. The vendor ZIP is committed
(`packages/PhonerLite64.zip`) because the sandbox cannot reach phoner.de.

</details>

## 🖥️ Tested on

| Component | Version |
| --- | --- |
| OS | NixOS 26.11 «Zokor» (`nixos-unstable`) |
| DE / WM | KDE Plasma 6.8.1, KWin (Wayland session); XFCE 4.20 (X11 session) |
| Wine | wine-wow64 11.0 (`wineWow64Packages.stable`) |
| PhonerLite | 3.46 (2026-10-12) |

Hardware: AMD Ryzen 7 8845HS (Radeon 780M, amdgpu driver), x86_64, 1920x1080 @ 144 Hz.

> [!IMPORTANT]
> The package builds against `wineWow64Packages.stable` because the `wayland` flavor has no
> X11 driver at all — without it the app does not start. A Wayland session is driven through
> XWayland; an X11 session runs directly. Verified on Plasma 6.8 (Wayland) and XFCE 4.20
> (X11); other DEs should work the same way, but have not been checked.

## ⬆️ Updating PhonerLite

1. Download the fresh `PhonerLite64.zip` from the
   [vendor's download page](https://www.phonerlite.de/download_en.htm).
2. Replace `packages/PhonerLite64.zip` with it.
3. Bump `version` in [`packages/phonerlite.nix`](packages/phonerlite.nix).

The ZIP is part of the repository because the GitHub CI sandbox has no network
access to the vendor.

## 📄 License

The packaging code in this repository is [MIT](LICENSE). PhonerLite itself is not covered by
that license — it is proprietary freeware from the vendor (see the
[vendor's license](https://www.phonerlite.de/index_en.htm)), bundled verbatim in
`packages/PhonerLite64.zip` for offline builds.

<div align="center">

If this saved you an evening of winecfg — consider giving it a ⭐

</div>
