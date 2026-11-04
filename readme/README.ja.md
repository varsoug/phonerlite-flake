<div align="center">

[🇬🇧 English](../README.md) | [🇨🇳 简体中文](README.zh-CN.md) | [🇪🇸 Español](README.es.md) | [🇧🇷 Português](README.pt-BR.md) | [🇩🇪 Deutsch](README.de.md) | [🇫🇷 Français](README.fr.md) | **🇯🇵 日本語** | [🇰🇷 한국어](README.ko.md) | [🇷🇺 Русский](README.ru.md) | [🇺🇦 Українська](README.uk.md)

# NixOS 版 PhonerLite

**Nix 用にパッケージ化された無料の SIP ソフトフォン — デスクトップ連携の落とし穴をすべて解消した状態で Wine 上で動作します。**

[![CI](https://img.shields.io/github/actions/workflow/status/varsoug/phonerlite-flake/ci.yml?style=flat-square&label=ci)](https://github.com/varsoug/phonerlite-flake/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/varsoug/phonerlite-flake?style=flat-square)](https://github.com/varsoug/phonerlite-flake/releases)
[![License](https://img.shields.io/github/license/varsoug/phonerlite-flake?style=flat-square)](../LICENSE)
[![NixOS unstable](https://img.shields.io/badge/nixos-unstable-blue.svg?style=flat-square&logo=nixos)](https://nixos.org)
[![Wine](https://img.shields.io/badge/wine-wow64%2011.0-732727?style=flat-square&logo=wine)](https://www.winehq.org)

[**クイックスタート**](#-クイックスタート) ·
[機能](#-機能) ·
[インストール](#-インストール) ·
[仕組み](#-仕組み) ·
[動作確認済み環境](#-動作確認済み環境)

</div>

---

[PhonerLite](https://www.phonerlite.de) は Windows 向けの無料（フリーウェア）SIP
ソフトフォンです。この flake はそれを NixOS / Nix on Linux 用にパッケージ化し、Wine で
**あるべき姿で**動作させます。ネイティブなウィンドウ装飾、アンチエイリアスの効いたフォント、
妥当な DPI、最小化からちゃんと戻るウィンドウ。

`pkgs.wine` を入れて `wine PhonerLite.exe` を実行するだけなら、数分で壁にぶつかります。
*「Bad EXE format」*、ドット絵のようなフォント、WinXP 風のウィンドウボタン、最小化すると
二度と戻らないウィンドウ、そして常に最小化状態で起動するアプリ。このパッケージはそれらを
すべて最初から解決しています。

## 🚀 クイックスタート

```bash
nix run github:varsoug/phonerlite-flake
```

初回はパッケージをビルドし（約 1 分）、PhonerLite を起動します。SIP アカウント、電話帳、
通話履歴は `~/.local/share/phonerlite/` に保存され、アプリは完全にポータブルなままです。
ベンダーのポータブル ZIP は flake に同梱されているため、ビルドにネットワークは不要です。

## ✨ 機能

|   |   |
|---|---|
| 🍷 **設定済みの Wine** | 専用の 64 ビットプレフィックス、適切なドライバ、レジストリと ini の修正は自動。 |
| 🪟 **ネイティブな装飾** | KWin/GNOME がタイトルバーを描画 — 内蔵の WinXP 風ボタンは出ません。 |
| 🔤 **くっきりしたフォント** | プレフィックスで完全なフォントスムージング（ClearType 相当）を有効化。 |
| 🖼️ **妥当な DPI** | 既定で 120 PPI で描画し、アイコンが粗くならないようにします。設定可能です。 |
| 🗂️ **分離されたプレフィックス** | `~/.local/share/phonerlite-prefix` に置かれ、`~/.wine` には一切触れません。 |
| 📦 **設定不要** | モジュール 1 行か `nix run` 1 回 — winecfg、winetricks、手作業のレジストリ編集は不要。 |
| 🔌 **ポータブルな状態** | アカウント、電話帳、ログは store とは独立に `~/.local/share/phonerlite/` に保存。 |

## 📦 インストール

### 方法 1 — NixOS モジュール（推奨）

**1.** システムの `flake.nix` に input を追加します。

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # ...ほかの input はそのまま...
    phonerlite.url = "github:varsoug/phonerlite-flake";
  };
```

**2.** モジュールを有効化します。

```nix
  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        # ...ほかのモジュールはそのまま...
        inputs.phonerlite.nixosModules.default
        { programs.phonerlite.enable = true; }
      ];
    };
  };
```

**3.** リビルドして起動します。

```bash
sudo nixos-rebuild switch --flake /path/to/your/flake#myhost
phonerlite
```

単なるパッケージとして使いたい場合は同じ結果です。

```nix
{ environment.systemPackages = [ inputs.phonerlite.packages.x86_64-linux.phonerlite ]; }
```

### 方法 2 — Overlay

```nix
nixpkgs.overlays = [ inputs.phonerlite.overlays.default ];
# あとは設定のどこでも:
environment.systemPackages = with pkgs; [ phonerlite ];
```

### 方法 3 — Flakes なし（旧式の設定）

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
> home-manager は不要です — flake の input は `nixpkgs` だけです。

## ⚙️ 設定

UI のスケールは既定で 120 PPI です（PhonerLite は 96 PPI を想定しているため、そのままだと
粗く見えます）。パッケージの呼び出し時に上書きできます。

```nix
pkgs.callPackage ./packages/phonerlite.nix { scalePPI = "96"; }  # または "144"
```

## 🔍 仕組み

<details>
<summary>各ワークアラウンドの裏側</summary>

**なぜ専用プレフィックスか。** `PhonerLite.exe` は 64 ビットの PE バイナリです。`~/.wine` が
32 ビットのプレフィックスだと、Wine は「Bad EXE format」で実行を拒否します。ランチャーは
`~/.local/share/phonerlite-prefix` に独自のプレフィックスを持ち、`~/.wine` には触れません。

**なぜ `wineWow64Packages.stable` で `.wayland` ではないのか。** Wine の `wayland` 版には
X11 ドライバが含まれていない（`winex11.drv` がない）ため、アプリが起動できません。
`stable`、`staging`、`full` にはどちらも含まれています。

**なぜ X11 を強制するのか（`env -u WAYLAND_DISPLAY`）。** 第一に、`winewayland.so` は
`xdg-decoration` プロトコルを実装しておらず、常に自前の WinXP 風タイトルバーを描画します。
レジストリキー `Decorated=Y` は X11 ドライバにのみ効きます。第二に、Wayland ドライバには
最小化すると再起動までウィンドウボタンが効かなくなる不具合があります。XWayland 経由なら
どちらも解消し、コンポジタが通常のタイトルバーを描画します。

**なぜインストーラーではなくポータブル ZIP か。** ベンダーはポータブル ZIP を配布してお
り、インストーラーはショートカットを作るだけです。ZIP は nix store に展開され、ランチャー
が初回起動時に `~/.local/share/phonerlite` にコピーしてそこから起動します。PhonerLite は
`sipper.ini`、電話帳、ログを `.exe` の隣に保存し、store のパスは読み取り専用のままです。

**起動のたびに書き込まれるレジストリキー**（冪等）:
- `HKCU\Control Panel\Desktop\Decorated=Y` — ウィンドウ装飾をウィンドウマネージャに任せる;
- `FontSmoothing=2`、`FontSmoothingType=2`、`FontSmoothingOrientation=1`、
  `FontSmoothingGamma=0x578` — 完全なフォントアンチエイリアス（新しいプレフィックスはドット
  絵のように描画されます）。
- `LogPixels` は意図的に**設定しません**。設定すると PhonerLite がメインウィンドウを作る前に
  ハングします。

**起動のたびの ini 修正**（冪等）: `WindowState=0`（そうしないと最小化状態で開きます — 終了
時にその状態を保存するため）と `ScaleDefaultPPI=<scalePPI>`（UI スケール）。

**パッケージングの癖。** Nix 標準の展開ツールはベンダー ZIP を扱えません（「do not know how
to unpack source archive」）。そのため `dontUnpack = true` にして `installPhase` で `unzip`
により展開します。非 ASCII のファイル名による非ゼロ終了は無視し、言語別のライセンス複製は
削除します。アイコンは `.exe` のリソースから `wrestool`/`icotool` で取り出します。

**CI。** `.github/workflows/ci.yml` は push のたびにパッケージをビルドし、成果物（ランチャー、
desktop ファイル、アイコン）を検証します。ベンダー ZIP をリポジトリに含めているのは
（`packages/PhonerLite64.zip`）、サンドボックスから phoner.de に接続できないためです。

</details>

## 🖥️ 動作確認済み環境

| コンポーネント | バージョン |
| --- | --- |
| OS | NixOS 26.11 «Zokor»（`nixos-unstable`） |
| DE / WM | KDE Plasma 6.8.1、KWin（Wayland セッション） |
| Wine | wine-wow64 11.0（`wineWow64Packages.stable`） |
| PhonerLite | 3.46（2026-10-12） |

ハードウェア: AMD Ryzen 7 8845HS（Radeon 780M、amdgpu ドライバ）、x86_64、1920x1080 @ 144 Hz。

> [!IMPORTANT]
> パッケージは `wineWow64Packages.stable` でビルドしています。`wayland` 版には X11 ドライバが
> まったく含まれず、それがないとアプリは起動しないためです。ほかのデスクトップ環境
> （GNOME、COSMIC、sway など）でも XWayland 経由で動くはずですが、確認済みは Plasma 6.8
> のみです。

## ⬆️ PhonerLite の更新

1. [ベンダーのダウンロードページ](https://www.phonerlite.de/download_en.htm)から新しい
   `PhonerLite64.zip` を取得します。
2. `packages/PhonerLite64.zip` をそれで置き換えます。
3. [`packages/phonerlite.nix`](../packages/phonerlite.nix) の `version` を上げます。

ZIP がリポジトリに含まれているのは、GitHub CI のサンドボックスがベンダーに接続できない
ためです。

## 📄 ライセンス

PhonerLite 自体はクローズドソースのフリーウェアです（
[ベンダーのライセンス](https://www.phonerlite.de/index_en.htm)参照）。無償利用と再配布は
許可されています。このリポジトリのパッケージングコードは MIT です。

<div align="center">

これで winecfg への夜が 1 晩浮いたら — ⭐ をお願いします

</div>
