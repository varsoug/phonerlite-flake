<div align="center">

[🇬🇧 English](../README.md) | [🇨🇳 简体中文](README.zh-CN.md) | [🇪🇸 Español](README.es.md) | [🇧🇷 Português](README.pt-BR.md) | **🇩🇪 Deutsch** | [🇫🇷 Français](README.fr.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇷🇺 Русский](README.ru.md) | [🇺🇦 Українська](README.uk.md)

# PhonerLite für NixOS

**Ein kostenloses SIP-Softphone, für Nix verpackt — läuft auf Wine, mit allen Stolperfallen der Desktop-Integration bereits gelöst.**

[![CI](https://img.shields.io/github/actions/workflow/status/varsoug/phonerlite-flake/ci.yml?style=flat-square&label=ci)](https://github.com/varsoug/phonerlite-flake/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/varsoug/phonerlite-flake?style=flat-square)](https://github.com/varsoug/phonerlite-flake/releases)
[![License](https://img.shields.io/github/license/varsoug/phonerlite-flake?style=flat-square)](../LICENSE)
[![NixOS unstable](https://img.shields.io/badge/nixos-unstable-blue.svg?style=flat-square&logo=nixos)](https://nixos.org)
[![Wine](https://img.shields.io/badge/wine-wow64%2011.0-732727?style=flat-square&logo=wine)](https://www.winehq.org)

[**Schnellstart**](#-schnellstart) ·
[Funktionen](#-funktionen) ·
[Installation](#-installation) ·
[Wie es funktioniert](#-wie-es-funktioniert) ·
[Getestet auf](#-getestet-auf)

</div>

---

[PhonerLite](https://www.phonerlite.de) ist ein kostenloses (Freeware-)SIP-Softphone für Windows.
Dieser Flake-Verpackt es für NixOS / Nix unter Linux und führt es über Wine **so aus, wie es
sein soll**: native Fensterdekoration, geglättete Schriften, sinnvolle DPI, ein Fenster, das
Minimieren übersteht.

Wenn du nur `pkgs.wine` installierst und `wine PhonerLite.exe` startest, läufst du binnen
Minuten gegen eine Wand: *„Bad EXE format"*, verpixelte Schriften, Fensterknöpfe im WinXP-Stil,
ein Fenster, das nach dem Minimieren nie wiederkommt, und eine App, die immer minimiert
startet. Dieses Paket behebt all das von Haus aus.

## 🚀 Schnellstart

```bash
nix run github:varsoug/phonerlite-flake
```

Der erste Start baut das Paket (etwa eine Minute) und startet PhonerLite. SIP-Konten, Telefonbuch
und Anrufliste liegen in `~/.local/share/phonerlite/` — die App bleibt voll portabel. Das portable
ZIP des Herstellers gehört zum Flake, der Build braucht also keinen Netzzugang.

## ✨ Funktionen

|   |   |
|---|---|
| 🍷 **Wine, vorkonfiguriert** | Eigenes 64-Bit-Prefix, passender Treiber, Registry- und Ini-Fixes automatisch. |
| 🪟 **Natives Fenster** | KWin/GNOME zeichnen die Titelleiste — keine eingebauten WinXP-Knöpfe. |
| 🔤 **Scharfe Schriften** | Vollständiges Font-Smoothing (ClearType-ähnlich) im Prefix aktiviert. |
| 🖼️ **Sinnvolle DPI** | Standardmäßig 120 PPI, damit die Symbole nicht klotzig wirken; einstellbar. |
| 🗂️ **Isoliertes Prefix** | Liegt in `~/.local/share/phonerlite-prefix`; dein `~/.wine` wird nie berührt. |
| 📦 **Keine Einrichtung** | Eine Modulzeile oder ein `nix run` — kein winecfg, kein winetricks, keine Registry-Handarbeit. |
| 🔌 **Portabler Zustand** | Konten, Telefonbuch und Logs bleiben in `~/.local/share/phonerlite/`, unabhängig vom Store. |

## 📦 Installation

### Option 1 — NixOS-Modul (empfohlen)

**1.** Input in die `flake.nix` deines Systems aufnehmen:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # ...deine anderen Inputs...
    phonerlite.url = "github:varsoug/phonerlite-flake";
  };
```

**2.** Modul aktivieren:

```nix
  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        # ...deine anderen Module...
        inputs.phonerlite.nixosModules.default
        { programs.phonerlite.enable = true; }
      ];
    };
  };
```

**3.** Neu bauen und starten:

```bash
sudo nixos-rebuild switch --flake /path/to/your/flake#myhost
phonerlite
```

Lieber als normales Paket? Gleiches Ergebnis:

```nix
{ environment.systemPackages = [ inputs.phonerlite.packages.x86_64-linux.phonerlite ]; }
```

### Option 2 — Overlay

```nix
nixpkgs.overlays = [ inputs.phonerlite.overlays.default ];
# dann, überall in deiner Konfiguration:
environment.systemPackages = with pkgs; [ phonerlite ];
```

### Option 3 — Ohne Flakes (legacy config)

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
> Home-Manager ist nicht nötig — der einzige Flake-Input ist `nixpkgs`.

## ⚙️ Konfiguration

Die UI-Skalierung steht standardmäßig auf 120 PPI (PhonerLite ist auf 96 PPI ausgelegt und
wirkt sonst klotzig). Beim Aufruf des Pakets überschreibbar:

```nix
pkgs.callPackage ./packages/phonerlite.nix { scalePPI = "96"; }  # oder "144"
```

## 🔍 Wie es funktioniert

<details>
<summary>Die Details hinter jedem Workaround</summary>

**Warum ein eigenes Prefix.** `PhonerLite.exe` ist eine 64-Bit-PE-Binary. Ist dein `~/.wine` ein
32-Bit-Prefix, verweigert Wine den Start mit „Bad EXE format". Der Launcher führt sein eigenes
Prefix unter `~/.local/share/phonerlite-prefix` und rührt `~/.wine` nie an.

**Warum `wineWow64Packages.stable`, nicht `.wayland`.** Der `wayland`-Build von Wine enthält
gar keinen X11-Treiber (`winex11.drv` fehlt), die App kann also nicht starten. `stable`,
`staging` und `full` enthalten beide Treiber.

**Warum der X11-Treiber erzwungen wird (`env -u WAYLAND_DISPLAY`).** Erstens implementiert
`winewayland.so` das `xdg-decoration`-Protokoll nicht — es zeichnet immer seine eigene Titelleiste
im WinXP-Stil, und der Registry-Schlüssel `Decorated=Y` wirkt nur auf den X11-Treiber. Zweitens
hat der Wayland-Treiber einen Fehler: nach dem Minimieren funktionieren die Fensterknöpfe bis
zum Neustart nicht. Über XWayland verschwinden beide Probleme und der Compositor zeichnet eine
normale Titelleiste.

**Warum das portable ZIP, nicht der Installer.** Der Hersteller liefert ein portables ZIP; der
Installer legt nur Verknüpfungen an. Das ZIP wird in den Nix-Store entpackt, der Launcher kopiert
es beim ersten Start nach `~/.local/share/phonerlite` und startet es von dort — PhonerLite legt
`sipper.ini`, Telefonbuch und Logs neben die `.exe`, der Store-Pfad bleibt schreibgeschützt.

**Registry-Schlüssel bei jedem Start** (idempotent):
- `HKCU\Control Panel\Desktop\Decorated=Y` — Fensterdekoration an den Fenstermanager abgeben;
- `FontSmoothing=2`, `FontSmoothingType=2`, `FontSmoothingOrientation=1`,
  `FontSmoothingGamma=0x578` — volles Font-Antialiasing (ein frisches Prefix rendert verpixelt).
- `LogPixels` wird bewusst **nicht** gesetzt: damit hängt PhonerLite, bevor es sein Hauptfenster
  erzeugt.

**Ini-Fixes bei jedem Start** (idempotent): `WindowState=0` (sonst öffnet die App minimiert — sie
speichert diesen Zustand beim Beenden) und `ScaleDefaultPPI=<scalePPI>` (UI-Skalierung).

**Verpackungsdetails.** Der Nix-eigene Entpacker kann das Hersteller-ZIP nicht öffnen („do not
know how to unpack source archive"), daher `dontUnpack = true` und Entpacken per `unzip` in
`installPhase`; der Exit-Code ungleich null wegen der Nicht-ASCII-Namen wird ignoriert, und die
sprachspezifischen Lizenzkopien fallen weg. Das Symbol wird mit `wrestool`/`icotool` aus den
Ressourcen der `.exe` extrahiert.

**CI.** `.github/workflows/ci.yml` baut das Paket und prüft seine Ausgaben (Launcher, Desktop-Datei,
Symbol) bei jedem Push. Das Hersteller-ZIP ist eingecheckt (`packages/PhonerLite64.zip`), weil die
Sandbox phoner.de nicht erreicht.

</details>

## 🖥️ Getestet auf

| Komponente | Version |
| --- | --- |
| OS | NixOS 26.11 «Zokor» (`nixos-unstable`) |
| DE / WM | KDE Plasma 6.8.1, KWin (Wayland-Sitzung) |
| Wine | wine-wow64 11.0 (`wineWow64Packages.stable`) |
| PhonerLite | 3.46 (2026-10-12) |

Hardware: AMD Ryzen 7 8845HS (Radeon 780M, amdgpu-Treiber), x86_64, 1920x1080 @ 144 Hz.

> [!IMPORTANT]
> Das Paket baut gegen `wineWow64Packages.stable`, weil die `wayland`-Variante gar keinen
> X11-Treiber hat — ohne ihn startet die App nicht. Auf anderen DEs (GNOME, COSMIC, sway…)
> sollte es über XWayland funktionieren, verifiziert ist aber nur Plasma 6.8.

## ⬆️ PhonerLite aktualisieren

1. Das neue `PhonerLite64.zip` von der
   [Download-Seite des Herstellers](https://www.phonerlite.de/download_de.htm) laden.
2. `packages/PhonerLite64.zip` damit ersetzen.
3. `version` in [`packages/phonerlite.nix`](../packages/phonerlite.nix) erhöhen.

Das ZIP gehört zum Repository, weil die GitHub-CI-Sandbox keinen Netzzugang zum Hersteller hat.

## 📄 Lizenz

PhonerLite selbst ist Freeware mit geschlossenem Quelltext (siehe
[Lizenz des Herstellers](https://www.phonerlite.de/index_de.htm)); freie Nutzung und
Weitergabe sind erlaubt. Der Verpackungscode in diesem Repository steht unter MIT.

<div align="center">

Wenn dir das einen Abend mit winecfg erspart hat — ein ⭐ wäre nett

</div>
