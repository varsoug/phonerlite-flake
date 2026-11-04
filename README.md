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

## Technical details (как это устроено)

<details>
<summary>Разбор каждого «костыля» в пакете</summary>

**Почему отдельный префикс, а не `~/.wine`.** `PhonerLite.exe` — 64-битный PE. Если дефолтный префикс пользователя 32-битный, Wine откажет с «Bad EXE format». Лauncher создаёт собственный префикс `~/.local/share/phonerlite-prefix` и никогда не трогает `~/.wine`.

**Почему `wineWow64Packages.stable`, а не `wineWow64Packages.wayland`.** У wayland-сборки Wine вообще нет X11-драйвера (`winex11.drv` отсутствует), приложение не стартует. У stable/staging/full оба драйвера есть.

**Почему запуск через X11 (`env -u WAYLAND_DISPLAY`).** Во-первых, у `winewayland.so` нет поддержки протокола `xdg-decoration` — он всегда рисует собственную рамку в стиле WinXP, а ключ реестра `Decorated=Y` действует только на X11-драйвере. Во-вторых, wayland-драйвер имеет баг: после сворачивания окна кнопки управления перестают работать до перезапуска приложения. Через XWayland обе проблемы исчезают, и KWin рисует нормальную рамку.

**Почему ZIP, а не установщик.** Вендор поставляет портативный ZIP; установщик лишь создаёт ярлыки. ZIP распаковывается в nix store, а launcher при первом запуске копирует его в `~/.local/share/phonerlite` и стартует оттуда — PhonerLite хранит `sipper.ini`, телефонную книгу и логи рядом с .exe, а store read-only.

**Реестр, который прописывается при каждом запуске** (идемпотентно):
- `HKCU\Control Panel\Desktop\Decorated=Y` — отдать декорирование оконного менеджера;
- `FontSmoothing=2`, `FontSmoothingType=2`, `FontSmoothingOrientation=1`, `FontSmoothingGamma=0x578` — полное сглаживание шрифтов (по умолчанию в префиксе текст рендерится пиксельно).
- `LogPixels` **намеренно не трогаем** — установка этого ключа заставляет PhonerLite зависнуть до создания главного окна.

**ini-правки при каждом запуске** (идемпотентно): `WindowState=0` (иначе приложение открывается свёрнутым — оно запоминает состояние в ini при выходе) и `ScaleDefaultPPI=<scalePPI>` (масштаб интерфейса; иначе иконки 96 PPI выглядят зубчатыми).

**Особенности распаковки.** `dontUnpack = true`, потому что стандартный unpackPhase не переваривает не-ASCII имена файлов в ZIP; распаковка идёт в installPhase через `unzip -j` (игнорируем ненулевой код возврата на warning'ах имён). Иконка извлекается из ресурсов .exe через `wrestool`/`icotool`.

</details>

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
