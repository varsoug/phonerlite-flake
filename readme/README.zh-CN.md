<div align="center">

[🇬🇧 English](../README.md) | **🇨🇳 简体中文** | [🇪🇸 Español](README.es.md) | [🇧🇷 Português](README.pt-BR.md) | [🇩🇪 Deutsch](README.de.md) | [🇫🇷 Français](README.fr.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇷🇺 Русский](README.ru.md) | [🇺🇦 Українська](README.uk.md)

# PhonerLite for NixOS

<img src="../docs/screenshot.png" width="420" alt="PhonerLite running through Wine">

**一款免费的 SIP 软电话，打包为 Nix 包 — 在 Wine 上运行，各类桌面集成问题均已解决。**

[![CI](https://img.shields.io/github/actions/workflow/status/varsoug/phonerlite-flake/ci.yml?style=flat-square&label=ci)](https://github.com/varsoug/phonerlite-flake/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/varsoug/phonerlite-flake?style=flat-square)](https://github.com/varsoug/phonerlite-flake/releases)
[![License](https://img.shields.io/github/license/varsoug/phonerlite-flake?style=flat-square)](../LICENSE)
[![NixOS unstable](https://img.shields.io/badge/nixos-unstable-blue.svg?style=flat-square&logo=nixos)](https://nixos.org)
[![Wine](https://img.shields.io/badge/wine-wow64%2011.0-732727?style=flat-square&logo=wine)](https://www.winehq.org)

[**快速开始**](#-快速开始) ·
[功能](#-功能) ·
[安装](#-安装) ·
[工作原理](#-工作原理) ·
[已测试环境](#-已测试环境)

</div>

---

[PhonerLite](https://www.phonerlite.de) 是一款面向 Windows 的免费（freeware）SIP 软电话。
本 flake 将其打包供 NixOS / Nix on Linux 使用，并通过 Wine 运行，**按它应有的方式运行**：
原生窗口装饰、字体抗锯齿、合理的 DPI，以及能够正常从最小化恢复的窗口。

如果只是安装 `pkgs.wine` 然后运行 `wine PhonerLite.exe`，几分钟内就会撞墙：*「Bad EXE
format」*、像素化的字体、WinXP 风格的窗口按钮、最小化后再也回不来的窗口，以及每次都
以最小化状态启动的程序。本包已从根源上解决这些问题。

## 👥 适合谁使用

- 你使用 **NixOS 或 Nix**（是否用 flakes 都可以），需要一个在 Linux 上运行的 SIP 软电话。
- 你在 **Wayland 下的 KDE Plasma** 上工作 — 这里 `wine PhonerLite.exe` 通常会出现问题。
- 你不想**手动配置**：不用 winecfg、winetricks，也不用手改注册表。
- 你要的是 **PhonerLite 的官方构建**（freeware、闭源），而不是替代品。

## 🚀 快速开始

```bash
nix run github:varsoug/phonerlite-flake
```

首次运行会构建软件包（约一分钟）并启动 PhonerLite。SIP 账户、电话簿和通话记录都位于
`~/.local/share/phonerlite/` — 程序保持完全便携。厂商的便携版 ZIP 随 flake 一起分发，
因此构建过程无需联网。

## ✨ 功能

|   |   |
|---|---|
| 🍷 **预配置的 Wine** | 独立的 64 位前缀、正确的驱动选择，注册表与 ini 修正自动完成。 |
| 🪟 **原生窗口装饰** | 由 KWin/GNOME 绘制标题栏 — 不出现内置的 WinXP 按钮。 |
| 🔤 **清晰字体** | 在前缀中启用完整字体平滑（等效 ClearType）。 |
| 🖼️ **合理 DPI** | 默认以 120 PPI 渲染，避免图标发虚；可配置。 |
| 🗂️ **隔离前缀** | 位于 `~/.local/share/phonerlite-prefix`；不会触碰你的 `~/.wine`。 |
| 📦 **零配置** | 一行模块配置或一次 `nix run` — 无需 winecfg、winetricks 或手动改注册表。 |
| 🔌 **便携状态** | 账户、电话簿和日志保存在 `~/.local/share/phonerlite/`，与 store 无关。 |

## 📦 安装

### 方案 1 — NixOS 模块（推荐）

**1.** 在系统 `flake.nix` 中添加输入：

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # ...你的其他输入...
    phonerlite.url = "github:varsoug/phonerlite-flake";
  };
```

**2.** 启用模块：

```nix
  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        # ...你的其他模块...
        inputs.phonerlite.nixosModules.default
        { programs.phonerlite.enable = true; }
      ];
    };
  };
```

**3.** 重建并启动：

```bash
sudo nixos-rebuild switch --flake /path/to/your/flake#myhost
phonerlite
```

只想当作普通软件包？效果一样：

```nix
{ environment.systemPackages = [ inputs.phonerlite.packages.x86_64-linux.phonerlite ]; }
```

### 方案 2 — Overlay

```nix
nixpkgs.overlays = [ inputs.phonerlite.overlays.default ];
# 然后在配置中的任意位置：
environment.systemPackages = with pkgs; [ phonerlite ];
```

### 方案 3 — 不使用 flakes（旧式配置）

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
> 不需要 home-manager — flake 唯一输入是 `nixpkgs`。

## ⚙️ 配置

界面缩放默认 120 PPI（PhonerLite 按 96 PPI 设计，否则显得粗糙）。调用包时可覆盖：

```nix
pkgs.callPackage ./packages/phonerlite.nix { scalePPI = "96"; }  # 或 "144"
```

## 🔍 工作原理

<details>
<summary>每个变通方案背后的细节</summary>

**为什么要独立前缀。** `PhonerLite.exe` 是 64 位 PE 程序。如果你的 `~/.wine` 是 32 位前缀，
Wine 会以「Bad EXE format」拒绝运行。启动器使用自己的前缀
`~/.local/share/phonerlite-prefix`，绝不触碰 `~/.wine`。

**为什么用 `wineWow64Packages.stable` 而不是 `.wayland`。** `wayland` 版 Wine 完全没有 X11
驱动（缺少 `winex11.drv`），程序无法启动。`stable`、`staging` 和 `full` 都包含两种驱动。

**为什么强制 X11（`env -u WAYLAND_DISPLAY`）。** 首先，`winewayland.so` 未实现
`xdg-decoration` 协议 — 它总是自绘 WinXP 风格标题栏，而注册表键 `Decorated=Y` 只对 X11
驱动生效。其次，Wayland 驱动有个缺陷：最小化后窗口按钮失效，直到重启程序。通过 XWayland
两个问题都会消失，由合成器绘制正常标题栏。

**为什么用便携 ZIP 而不是安装程序。** 厂商提供便携 ZIP，安装程序只创建快捷方式。ZIP 被
解包进 nix store，启动器在首次运行时复制到 `~/.local/share/phonerlite` 并从那里启动 —
PhonerLite 将 `sipper.ini`、电话簿和日志保存在 `.exe` 旁边，而 store 路径保持只读。

**每次启动写入的注册表键**（幂等）：
- `HKCU\Control Panel\Desktop\Decorated=Y` — 把窗口装饰交给窗口管理器；
- `FontSmoothing=2`、`FontSmoothingType=2`、`FontSmoothingOrientation=1`、
  `FontSmoothingGamma=0x578` — 完整字体抗锯齿（新建前缀渲染的字是像素化的）。
- 特意**不**设置 `LogPixels`：设置后 PhonerLite 会在创建主窗口前卡死。

**每次启动的 ini 修正**（幂等）：`WindowState=0`（否则程序以最小化状态打开 — 它退出时会
保存该状态）以及 `ScaleDefaultPPI=<scalePPI>`（界面缩放）。

**打包细节。** Nix 自带的解包器无法打开厂商 ZIP（「do not know how to unpack source
archive」），因此使用 `dontUnpack = true`，在 `installPhase` 中用 `unzip` 解包；因非 ASCII
文件名导致的非零退出码被忽略，并按语言剔除重复的许可证副本。图标用
`wrestool`/`icotool` 从 `.exe` 资源中提取。

**CI。** `.github/workflows/ci.yml` 在每次 push 时构建软件包并检查产物（启动器、desktop
文件、图标）。厂商 ZIP 已提交到仓库（`packages/PhonerLite64.zip`），因为沙箱无法访问
phoner.de。

</details>

## 🖥️ 已测试环境

| 组件 | 版本 |
| --- | --- |
| 操作系统 | NixOS 26.11 «Zokor»（`nixos-unstable`） |
| 桌面 / 窗口管理器 | KDE Plasma 6.8.1，KWin（Wayland 会话） |
| Wine | wine-wow64 11.0（`wineWow64Packages.stable`） |
| PhonerLite | 3.46（2026-10-12） |

硬件：AMD Ryzen 7 8845HS（Radeon 780M，amdgpu 驱动），x86_64，1920x1080 @ 144 Hz。

> [!IMPORTANT]
> 软件包针对 `wineWow64Packages.stable` 构建，因为 `wayland` 版本完全没有 X11 驱动 —
> 没有它程序无法启动。在其他桌面环境（GNOME、COSMIC、sway 等）预期可通过 XWayland
> 运行，但只在 Plasma 6.8 上验证过。

## ⬆️ 更新 PhonerLite

1. 从[厂商下载页](https://www.phonerlite.de/download_en.htm)下载新的 `PhonerLite64.zip`。
2. 用它替换 `packages/PhonerLite64.zip`。
3. 提高 [`packages/phonerlite.nix`](../packages/phonerlite.nix) 中的 `version`。

ZIP 是仓库的一部分，因为 GitHub CI 沙箱无法访问厂商站点。

## 📄 许可证

本仓库的打包代码采用 [MIT](../LICENSE)。PhonerLite 本身不在其覆盖范围内：它是厂商的专有 freeware（见[厂商许可证](https://www.phonerlite.de/index_en.htm)），原样放在 `packages/PhonerLite64.zip` 中以支持离线构建。

<div align="center">

如果它帮你省下一个折腾 winecfg 的晚上 — 欢迎给个 ⭐

</div>
