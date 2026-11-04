# PhonerLite for NixOS / Nix

[PhonerLite](https://www.phonerlite.de) — бесплатный (freeware) SIP-софтфон для Windows — упакован для NixOS/Nix и запускается через Wine **со всеми подводными камнями уже решёнными**.

Если вы просто поставили `pkgs.wine` и попробовали `wine PhonerLite.exe`, вы быстро наткнётесь на: «Bad EXE format», пиксельные шрифты, кнопки окна в стиле WinXP, окно, которое не разворачивается после сворачивания, и запуск свёрнутым. Этот пакет решает всё это из коробки — детали в шапке [`packages/phonerlite.nix`](packages/phonerlite.nix).

## Установка

### nix run (без установки)

```bash
nix run github:varsoug/phonerlite-flake
```

### В flake своей системы

```nix
{
  inputs.phonerlite-nix.url = "github:varsoug/phonerlite-flake";

  outputs = { nixpkgs, phonerlite-nix, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        # вариант 1: модуль
        phonerlite-nix.nixosModules.default
        { programs.phonerlite.enable = true; }

        # вариант 2: напрямую пакетом
        # { environment.systemPackages = [ phonerlite-nix.packages.x86_64-linux.phonerlite ]; }
      ];
    };
  };
}
```

### Overlay

```nix
nixpkgs.overlays = [ inputs.phonerlite-nix.overlays.default ];
# затем pkgs.phonerlite
```

> Home-manager не нужен: flake зависит только от nixpkgs.

## Что настраивается автоматически

- **Отдельный 64-битный Wine-префикс** `~/.local/share/phonerlite-prefix` (ваш `~/.wine` не трогается).
- **Запуск через X11/XWayland**, а не через Wayland-драйвер Wine: у `winewayland.so` нет поддержки декораций композитора (кнопки всегда «WinXP») и есть баг, после которого сворачивание ломает управление окном. Ключ реестра `Decorated=Y` отдаёт рамку окна KWin.
- **Сглаженные шрифты** (ClearType-эквивалент через реестр).
- **Не открывается свёрнутым** (PhonerLite запоминает состояние «свёрнуто» в своём ini).
- **Масштаб 120 PPI** (`ScaleDefaultPPI`) — иначе иконки 96 PPI выглядят пиксельными. Переопредели, если нужно другое:

```nix
pkgs.callPackage ./packages/phonerlite.nix { scalePPI = "96"; }  # или "144"
```

Приложение, его настройки SIP, телефонная книга и логи живут в `~/.local/share/phonerlite/` (портативный режим PhonerLite).

## На чём тестировалось

| Компонент | Версия |
| --- | --- |
| ОС | NixOS 26.11 «Zokor» (`nixos-unstable`, rev `31ecbac`) |
| DE / WM | KDE Plasma 6.8.1, KWin (Wayland-сессия) |
| Wine | wine-wow64 11.0 (`wineWow64Packages.stable`) |
| PhonerLite | 3.46 (2026-10-12) |

Железо: AMD Ryzen 7 8845HS (Radeon 780M, драйвер amdgpu), x86_64, монитор 1920x1080@144 Гц.

> **Важно:** пакет собирается с `wineWow64Packages.stable`, потому что у `wineWow64Packages.wayland` нет X11-драйвера вообще — без него приложение не стартует. На других DE (GNOME, COSMIC, sway…) ожидается работа по XWayland, но проверено только на Plasma 6.8.

## Обновление версии

1. Скачайте свежий `PhonerLite64.zip` со [страницы загрузки](https://www.phonerlite.de/download_en.htm).
2. Обновите `version` и `hash` в `packages/phonerlite.nix`:

```bash
nix hash file PhonerLite64.zip
```

## Лицензия

PhonerLite — freeware с закрытым исходным кодом (см. [лицензию](https://www.phonerlite.de/index_en.htm)); разрешено бесплатное использование и распространение. Код упаковки в этом репозитории — MIT.
