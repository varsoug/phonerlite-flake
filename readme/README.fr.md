<div align="center">

[🇬🇧 English](../README.md) | [🇨🇳 简体中文](README.zh-CN.md) | [🇪🇸 Español](README.es.md) | [🇧🇷 Português](README.pt-BR.md) | [🇩🇪 Deutsch](README.de.md) | **🇫🇷 Français** | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇷🇺 Русский](README.ru.md) | [🇺🇦 Українська](README.uk.md)

# PhonerLite pour NixOS

<img src="../docs/screenshot.png" width="420" alt="PhonerLite running through Wine">

**Un softphone SIP gratuit, empaqueté pour Nix — s'exécute sous Wine avec tous les pièges de l'intégration au bureau déjà résolus.**

[![CI](https://img.shields.io/github/actions/workflow/status/varsoug/phonerlite-flake/ci.yml?style=flat-square&label=ci)](https://github.com/varsoug/phonerlite-flake/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/varsoug/phonerlite-flake?style=flat-square)](https://github.com/varsoug/phonerlite-flake/releases)
[![License](https://img.shields.io/github/license/varsoug/phonerlite-flake?style=flat-square)](../LICENSE)
[![NixOS unstable](https://img.shields.io/badge/nixos-unstable-blue.svg?style=flat-square&logo=nixos)](https://nixos.org)
[![Wine](https://img.shields.io/badge/wine-wow64%2011.0-732727?style=flat-square&logo=wine)](https://www.winehq.org)

[**Démarrage rapide**](#-démarrage-rapide) ·
[Fonctionnalités](#-fonctionnalités) ·
[Installation](#-installation) ·
[Comment ça marche](#-comment-ça-marche) ·
[Testé sur](#-testé-sur)

</div>

---

[PhonerLite](https://www.phonerlite.de) est un softphone SIP gratuit (freeware) pour Windows.
Ce flake l'empaquette pour NixOS / Nix sous Linux et l'exécute via Wine **comme il doit
tourner** : décoration de fenêtre native, polices lissées, DPI raisonnable, une fenêtre qui
survit à la réduction.

Si vous installez juste `pkgs.wine` et lancez `wine PhonerLite.exe`, vous vous heurtez à un mur
en quelques minutes : *« Bad EXE format »*, polices pixelisées, boutons de fenêtre style WinXP,
une fenêtre qui ne revient jamais après réduction, et une appli qui se rouvre toujours réduite.
Ce paquet corrige tout cela d'emblée.

## 👥 Pour qui ?

- Vous utilisez **NixOS ou Nix** (avec ou sans flakes) et il vous faut un softphone SIP sous Linux.
- Vous êtes sous **KDE Plasma en Wayland** — là où `wine PhonerLite.exe` échoue habituellement.
- Vous ne voulez **rien configurer à la main** : ni winecfg, ni winetricks, ni registre.
- Vous voulez le **build officiel** de PhonerLite (freeware, closed source) et non un substitut.

## 🚀 Démarrage rapide

```bash
nix run github:varsoug/phonerlite-flake
```

Le premier lancement construit le paquet (environ une minute) et démarre PhonerLite. Les comptes
SIP, le carnet d'adresses et l'historique vivent dans `~/.local/share/phonerlite/` — l'application
reste entièrement portable. Le ZIP portable de l'éditeur est fourni avec le flake : la
construction ne nécessite donc aucun accès réseau.

## ✨ Fonctionnalités

|   |   |
|---|---|
| 🍷 **Wine pré-réglé** | Préfixe 64 bits dédié, bon pilote, corrections de registre et d'ini automatiques. |
| 🪟 **Décoration native** | KWin/GNOME dessinent la barre de titre — pas de boutons WinXP intégrés. |
| 🔤 **Polices nettes** | Lissage complet des polices (équivalent ClearType) activé dans le préfixe. |
| 🖼️ **DPI raisonnable** | Rendu à 120 PPI par défaut pour éviter les icônes grossières ; configurable. |
| 🗂️ **Préfixe isolé** | Situé dans `~/.local/share/phonerlite-prefix` ; votre `~/.wine` n'est jamais touché. |
| 📦 **Zéro configuration** | Une ligne de module ou un `nix run` — sans winecfg, winetricks ni registre à la main. |
| 🔌 **État portable** | Comptes, carnet et journaux restent dans `~/.local/share/phonerlite/`, hors du store. |

## 📦 Installation

### Option 1 — Module NixOS (recommandé)

**1.** Ajoutez l'entrée dans le `flake.nix` de votre système :

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # ...vos autres entrées...
    phonerlite.url = "github:varsoug/phonerlite-flake";
  };
```

**2.** Activez le module :

```nix
  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        # ...vos autres modules...
        inputs.phonerlite.nixosModules.default
        { programs.phonerlite.enable = true; }
      ];
    };
  };
```

**3.** Reconstruisez et lancez :

```bash
sudo nixos-rebuild switch --flake /path/to/your/flake#myhost
phonerlite
```

Plutôt un simple paquet ? Même résultat :

```nix
{ environment.systemPackages = [ inputs.phonerlite.packages.x86_64-linux.phonerlite ]; }
```

### Option 2 — Overlay

```nix
nixpkgs.overlays = [ inputs.phonerlite.overlays.default ];
# puis, partout dans votre configuration :
environment.systemPackages = with pkgs; [ phonerlite ];
```

### Option 3 — Sans flakes (config legacy)

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
> Home-manager n'est pas requis — la seule entrée du flake est `nixpkgs`.

## ⚙️ Configuration

L'échelle de l'interface vaut 120 PPI par défaut (PhonerLite cible 96 PPI et paraît grossier
sinon). Modifiable à l'appel du paquet :

```nix
pkgs.callPackage ./packages/phonerlite.nix { scalePPI = "96"; }  # ou "144"
```

## 🔍 Comment ça marche

<details>
<summary>Le détail derrière chaque contournement</summary>

**Pourquoi un préfixe dédié.** `PhonerLite.exe` est un binaire PE 64 bits. Si votre `~/.wine` est
un préfixe 32 bits, Wine refuse de le lancer avec « Bad EXE format ». Le lanceur garde son propre
préfixe dans `~/.local/share/phonerlite-prefix` et ne touche jamais `~/.wine`.

**Pourquoi `wineWow64Packages.stable` et non `.wayland`.** La variante `wayland` de Wine
n'embarque aucun pilote X11 (`winex11.drv` absent) : l'application ne peut pas démarrer.
`stable`, `staging` et `full` contiennent les deux pilotes.

**Pourquoi forcer X11 (`env -u WAYLAND_DISPLAY`).** D'une part, `winewayland.so` n'implémente pas
le protocole `xdg-decoration` — il dessine toujours sa barre de titre style WinXP, et la clé de
registre `Decorated=Y` n'agit que sur le pilote X11. D'autre part, le pilote Wayland a un bug :
après réduction, les boutons de fenêtre cessent de fonctionner jusqu'au redémarrage. Via
XWayland, les deux problèmes disparaissent et le compositeur dessine une barre de titre normale.

**Pourquoi le ZIP portable, pas l'installateur.** L'éditeur fournit un ZIP portable ; l'installateur
ne crée que des raccourcis. Le ZIP est déballé dans le store Nix, le lanceur le copie dans
`~/.local/share/phonerlite` au premier lancement et démarre depuis là — PhonerLite garde
`sipper.ini`, son carnet et ses journaux à côté du `.exe`, le chemin du store restant en lecture
seule.

**Clés de registre écrites à chaque lancement** (idempotent) :
- `HKCU\Control Panel\Desktop\Decorated=Y` — confier la décoration de fenêtre au gestionnaire ;
- `FontSmoothing=2`, `FontSmoothingType=2`, `FontSmoothingOrientation=1`,
  `FontSmoothingGamma=0x578` — lissage complet des polices (un préfixe neuf rend en pixelisé).
- `LogPixels` n'est volontairement **pas** défini : avec lui, PhonerLite se bloque avant de créer
  sa fenêtre principale.

**Corrections ini à chaque lancement** (idempotent) : `WindowState=0` (sinon l'application
s'ouvre réduite — elle enregistre cet état à la fermeture) et `ScaleDefaultPPI=<scalePPI>`
(échelle de l'interface).

**Détails d'empaquetage.** Le déballage intégré de Nix n'ouvre pas le ZIP de l'éditeur (« do not
know how to unpack source archive »), d'où `dontUnpack = true` et un déballage par `unzip` dans
`installPhase` ; son code de sortie non nul sur les noms non-ASCII est ignoré, et les copies de
licence par langue sont retirées. L'icône est extraite des ressources du `.exe` avec
`wrestool`/`icotool`.

**CI.** `.github/workflows/ci.yml` construit le paquet et vérifie ses sorties (lanceur, fichier
desktop, icône) à chaque push. Le ZIP de l'éditeur est versionné
(`packages/PhonerLite64.zip`) car la sandbox ne peut pas joindre phoner.de.

</details>

## 🖥️ Testé sur

| Composant | Version |
| --- | --- |
| OS | NixOS 26.11 « Zokor » (`nixos-unstable`) |
| DE / WM | KDE Plasma 6.8.1, KWin (session Wayland) |
| Wine | wine-wow64 11.0 (`wineWow64Packages.stable`) |
| PhonerLite | 3.46 (2026-10-12) |

Matériel : AMD Ryzen 7 8845HS (Radeon 780M, pilote amdgpu), x86_64, 1920x1080 @ 144 Hz.

> [!IMPORTANT]
> Le paquet est construit contre `wineWow64Packages.stable` car la variante `wayland` n'a aucun
> pilote X11 — sans lui, l'application ne démarre pas. Sur d'autres DE (GNOME, COSMIC, sway…)
> cela devrait fonctionner via XWayland, mais seule Plasma 6.8 a été vérifiée.

## ⬆️ Mettre à jour PhonerLite

1. Téléchargez le nouveau `PhonerLite64.zip` depuis la
   [page de téléchargement de l'éditeur](https://www.phonerlite.de/download_en.htm).
2. Remplacez `packages/PhonerLite64.zip` par celui-ci.
3. Incrémentez `version` dans [`packages/phonerlite.nix`](../packages/phonerlite.nix).

Le ZIP fait partie du dépôt car la sandbox de la CI GitHub n'a pas accès à l'éditeur.

## 📄 Licence

Le code d'empaquetage de ce dépôt est sous [MIT](../LICENSE). PhonerLite lui-même n'est pas couvert : c'est un freeware propriétaire de l'éditeur (voir la [licence de l'éditeur](https://www.phonerlite.de/index_en.htm)), livré tel quel dans `packages/PhonerLite64.zip` pour permettre les builds hors ligne.

<div align="center">

Si cela vous a épargné une soirée de winecfg — un ⭐ serait apprécié

</div>
