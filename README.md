<div align="center">

# PhonerLite for NixOS

**A free SIP softphone, packaged for Nix — running on Wine with every desktop-integration pitfall already solved.**

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

The UI scale defaults to 120 PPI (PhonerLite targets 96 PPI and looks blocky otherwise).
Override it when calling the package:

```nix
pkgs.callPackage ./packages/phonerlite.nix { scalePPI = "96"; }  # or "144"
```

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
minimized — it saves that state on exit) and `ScaleDefaultPPI=<scalePPI>` (UI scale).

**Packing quirks.** `dontUnpack = true` because the generic unpack phase cannot handle the
ZIP's non-ASCII member names; extraction runs in `installPhase` via `unzip -j` (its non-zero
exit on name warnings is ignored). The icon is extracted from the `.exe` resources with
`wrestool`/`icotool`.

</details>

## 🖥️ Tested on

| Component | Version |
| --- | --- |
| OS | NixOS 26.11 «Zokor» (`nixos-unstable`) |
| DE / WM | KDE Plasma 6.8.1, KWin (Wayland session) |
| Wine | wine-wow64 11.0 (`wineWow64Packages.stable`) |
| PhonerLite | 3.46 (2026-10-12) |

Hardware: AMD Ryzen 7 8845HS (Radeon 780M, amdgpu driver), x86_64, 1920x1080 @ 144 Hz.

> [!IMPORTANT]
> The package builds against `wineWow64Packages.stable` because the `wayland` flavor has no
> X11 driver at all — without it the app does not start. On other DEs (GNOME, COSMIC, sway…)
> it is expected to work through XWayland, but only Plasma 6.8 has been verified.

## ⬆️ Updating PhonerLite

1. Download the fresh `PhonerLite64.zip` from the
   [vendor's download page](https://www.phonerlite.de/download_en.htm).
2. Update `version` and `hash` in [`packages/phonerlite.nix`](packages/phonerlite.nix):

```bash
nix hash file PhonerLite64.zip
```

## 📄 License

PhonerLite itself is freeware with closed sources (see the
[vendor's license](https://www.phonerlite.de/index_en.htm)); free use and redistribution are
allowed. The packaging code in this repository is MIT.

<div align="center">

If this saved you an evening of winecfg — consider giving it a ⭐

</div>
