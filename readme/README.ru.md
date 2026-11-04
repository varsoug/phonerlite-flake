<div align="center">

[🇬🇧 English](../README.md) | [🇨🇳 简体中文](README.zh-CN.md) | [🇪🇸 Español](README.es.md) | [🇧🇷 Português](README.pt-BR.md) | [🇩🇪 Deutsch](README.de.md) | [🇫🇷 Français](README.fr.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | **🇷🇺 Русский** | [🇺🇦 Українська](README.uk.md)

# PhonerLite для NixOS

**Бесплатный SIP-софтфон, упакованный для Nix — работает на Wine со всеми исправленными проблемами интеграции с рабочим столом.**

[![CI](https://img.shields.io/github/actions/workflow/status/varsoug/phonerlite-flake/ci.yml?style=flat-square&label=ci)](https://github.com/varsoug/phonerlite-flake/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/varsoug/phonerlite-flake?style=flat-square)](https://github.com/varsoug/phonerlite-flake/releases)
[![License](https://img.shields.io/github/license/varsoug/phonerlite-flake?style=flat-square)](../LICENSE)
[![NixOS unstable](https://img.shields.io/badge/nixos-unstable-blue.svg?style=flat-square&logo=nixos)](https://nixos.org)
[![Wine](https://img.shields.io/badge/wine-wow64%2011.0-732727?style=flat-square&logo=wine)](https://www.winehq.org)

[**Быстрый старт**](#-быстрый-старт) ·
[Возможности](#-возможности) ·
[Установка](#-установка) ·
[Как это работает](#-как-это-работает) ·
[Проверено на](#-проверено-на)

</div>

---

[PhonerLite](https://www.phonerlite.de) — бесплатный (freeware) SIP-софтфон для Windows.
Этот флейк упаковывает его для NixOS / Nix на Linux и запускает через Wine **так, как он должен
работать**: нативные рамки окна, сглаженные шрифты, нормальный DPI, окно, которое переживает
сворачивание.

Если просто поставить `pkgs.wine` и запустить `wine PhonerLite.exe`, через минуту вы упрётесь
в стену: *«Bad EXE format»*, пиксельные шрифты, кнопки окна в стиле WinXP, окно, которое не
возвращается после сворачивания, и приложение, которое всегда открывается свёрнутым. Этот пакет
исправляет всё это из коробки.

## 🚀 Быстрый старт

```bash
nix run github:varsoug/phonerlite-flake
```

Первый запуск соберёт пакет (около минуты) и запустит PhonerLite. SIP-аккаунты, телефонная
книга и журнал звонков лежат в `~/.local/share/phonerlite/` — приложение остаётся полностью
переносимым. Портативный ZIP вендора поставляется вместе с флейком, поэтому сборке не нужен
доступ в сеть.

## ✨ Возможности

|   |   |
|---|---|
| 🍷 **Wine, уже настроен** | Отдельный 64-битный префикс, правильный драйвер, исправления реестра и ini применяются автоматически. |
| 🪟 **Нативные рамки** | KWin/GNOME рисуют заголовок — никаких встроенных кнопок WinXP. |
| 🔤 **Резкие шрифты** | Полное сглаживание шрифтов (аналог ClearType) включено в префиксе. |
| 🖼️ **Нормальный DPI** | По умолчанию рендерит на 120 PPI, чтобы иконки не были грубыми; настраивается. |
| 🗂️ **Изолированный префикс** | Живёт в `~/.local/share/phonerlite-prefix`; ваш `~/.wine` не трогается. |
| 📦 **Без настройки** | Одна строка модуля или один `nix run` — без winecfg, winetricks и ручной правки реестра. |
| 🔌 **Переносимое состояние** | Аккаунты, телефонная книга и логи остаются в `~/.local/share/phonerlite/`, независимо от стора. |

## 📦 Установка

### Вариант 1 — NixOS-модуль (рекомендуется)

**1.** Добавьте вход в `flake.nix` вашей системы:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # ...ваши остальные входы...
    phonerlite.url = "github:varsoug/phonerlite-flake";
  };
```

**2.** Включите модуль:

```nix
  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        # ...ваши остальные модули...
        inputs.phonerlite.nixosModules.default
        { programs.phonerlite.enable = true; }
      ];
    };
  };
```

**3.** Пересоберите и запустите:

```bash
sudo nixos-rebuild switch --flake /path/to/your/flake#myhost
phonerlite
```

Хотите просто как пакет? Результат тот же:

```nix
{ environment.systemPackages = [ inputs.phonerlite.packages.x86_64-linux.phonerlite ]; }
```

### Вариант 2 — Overlay

```nix
nixpkgs.overlays = [ inputs.phonerlite.overlays.default ];
# затем в любом месте конфигурации:
environment.systemPackages = with pkgs; [ phonerlite ];
```

### Вариант 3 — Без flakes (legacy config)

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
> Home-manager не требуется — единственный вход флейка это `nixpkgs`.

## ⚙️ Настройка

Масштаб интерфейса по умолчанию 120 PPI (PhonerLite рассчитан на 96 PPI и иначе выглядит
грубо). Переопределяется при вызове пакета:

```nix
pkgs.callPackage ./packages/phonerlite.nix { scalePPI = "96"; }  # или "144"
```

## 🔍 Как это работает

<details>
<summary>Детали за каждым обходным решением</summary>

**Зачем отдельный префикс.** `PhonerLite.exe` — 64-битный PE-бинарник. Если ваш `~/.wine` это
32-битный префикс, Wine откажется его запускать с «Bad EXE format». Лаунчер держит свой префикс
в `~/.local/share/phonerlite-prefix` и никогда не трогает `~/.wine`.

**Почему `wineWow64Packages.stable`, а не `.wayland`.** В сборке `wayland` вообще нет
X11-драйвера (`winex11.drv` отсутствует), поэтому приложение не запускается. В `stable`,
`staging` и `full` есть оба драйвера.

**Почему принудительно X11 (`env -u WAYLAND_DISPLAY`).** Во-первых, `winewayland.so` не
реализует протокол `xdg-decoration` — он всегда рисует свою рамку в стиле WinXP, а ключ реестра
`Decorated=Y` действует только на X11-драйвер. Во-вторых, в Wayland-драйвере есть баг: после
сворачивания окна кнопки управления перестают работать до перезапуска. Через XWayland обе
проблемы исчезают, и заголовок рисует композитор.

**Почему портативный ZIP, а не установщик.** Вендор поставляет портативный ZIP; установщик
только создаёт ярлыки. ZIP распаковывается в nix-стор, лаунчер при первом запуске копирует его в
`~/.local/share/phonerlite` и запускает оттуда — PhonerLite хранит `sipper.ini`, телефонную книгу
и логи рядом с `.exe`, а путь в сторе остаётся только для чтения.

**Ключи реестра при каждом запуске** (идемпотентно):
- `HKCU\Control Panel\Desktop\Decorated=Y` — отдать рамку окна оконному менеджеру;
- `FontSmoothing=2`, `FontSmoothingType=2`, `FontSmoothingOrientation=1`,
  `FontSmoothingGamma=0x578` — полное сглаживание шрифтов (свежий префикс рендерит пиксельно).
- `LogPixels` намеренно **не** ставится: с ним PhonerLite зависает до создания главного окна.

**Правки ini при каждом запуске** (идемпотентно): `WindowState=0` (иначе приложение
открывается свёрнутым — оно сохраняет это состояние при выходе) и `ScaleDefaultPPI=<scalePPI>`
(масштаб интерфейса).

**Особенности упаковки.** Собственный распаковщик Nix не умеет открывать ZIP вендора («do not
know how to unpack source archive»), поэтому `dontUnpack = true`, а распаковка идёт в
`installPhase` через `unzip`; ненулевой код возврата из-за не-ASCII имён игнорируется, а
локализованные копии лицензий отбрасываются. Иконка извлекается из ресурсов `.exe` через
`wrestool`/`icotool`.

**CI.** `.github/workflows/ci.yml` собирает пакет и проверяет его содержимое (лаунчер, desktop-файл,
иконку) на каждый push. ZIP вендора лежит в репозитории (`packages/PhonerLite64.zip`), потому что
песочница не может достучаться до phoner.de.

</details>

## 🖥️ Проверено на

| Компонент | Версия |
| --- | --- |
| ОС | NixOS 26.11 «Zokor» (`nixos-unstable`) |
| DE / WM | KDE Plasma 6.8.1, KWin (сеанс Wayland) |
| Wine | wine-wow64 11.0 (`wineWow64Packages.stable`) |
| PhonerLite | 3.46 (2026-10-12) |

Железо: AMD Ryzen 7 8845HS (Radeon 780M, драйвер amdgpu), x86_64, 1920x1080 @ 144 Гц.

> [!IMPORTANT]
> Пакет собирается с `wineWow64Packages.stable`, потому что у варианта `wayland` вообще нет
> X11-драйвера — без него приложение не запустится. На других DE (GNOME, COSMIC, sway…)
> ожидается работа через XWayland, но проверена только Plasma 6.8.

## ⬆️ Обновление PhonerLite

1. Скачайте свежий `PhonerLite64.zip` со
   [страницы загрузки вендора](https://www.phonerlite.de/download_en.htm).
2. Замените им `packages/PhonerLite64.zip`.
3. Поднимите `version` в [`packages/phonerlite.nix`](../packages/phonerlite.nix).

ZIP является частью репозитория, потому что у песочницы GitHub CI нет доступа к вендору.

## 📄 Лицензия

Сам PhonerLite — freeware с закрытым исходным кодом (см.
[лицензию вендора](https://www.phonerlite.de/index_en.htm)); свободное использование и
распространение разрешены. Код упаковки в этом репозитории — MIT.

<div align="center">

Если это спасло вам вечер с winecfg — поставьте ⭐

</div>
