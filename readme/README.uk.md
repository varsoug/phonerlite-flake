<div align="center">

[🇬🇧 English](../README.md) | [🇨🇳 简体中文](README.zh-CN.md) | [🇪🇸 Español](README.es.md) | [🇧🇷 Português](README.pt-BR.md) | [🇩🇪 Deutsch](README.de.md) | [🇫🇷 Français](README.fr.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇷🇺 Русский](README.ru.md) | **🇺🇦 Українська**

# PhonerLite для NixOS

**Безкоштовний SIP-софтфон, упакований для Nix — працює на Wine з усіма виправленими проблемами інтеграції з робочим столом.**

[![CI](https://img.shields.io/github/actions/workflow/status/varsoug/phonerlite-flake/ci.yml?style=flat-square&label=ci)](https://github.com/varsoug/phonerlite-flake/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/varsoug/phonerlite-flake?style=flat-square)](https://github.com/varsoug/phonerlite-flake/releases)
[![License](https://img.shields.io/github/license/varsoug/phonerlite-flake?style=flat-square)](../LICENSE)
[![NixOS unstable](https://img.shields.io/badge/nixos-unstable-blue.svg?style=flat-square&logo=nixos)](https://nixos.org)
[![Wine](https://img.shields.io/badge/wine-wow64%2011.0-732727?style=flat-square&logo=wine)](https://www.winehq.org)

[**Швидкий старт**](#-швидкий-старт) ·
[Можливості](#-можливості) ·
[Встановлення](#-встановлення) ·
[Як це працює](#-як-це-працює) ·
[Перевірено на](#-перевірено-на)

</div>

---

[PhonerLite](https://www.phonerlite.de) — безкоштовний (freeware) SIP-софтфон для Windows.
Цей флейк пакує його для NixOS / Nix на Linux і запускає через Wine **так, як він має
працювати**: нативні рамки вікна, згладжені шрифти, нормальний DPI, вікно, яке переживає
згортання.

Якщо просто встановити `pkgs.wine` і запустити `wine PhonerLite.exe`, за хвилину ви впретеся
в стіну: *«Bad EXE format»*, піксельні шрифти, кнопки вікна в стилі WinXP, вікно, яке не
повертається після згортання, і застосунок, що завжди відкривається згорнутим. Цей пакет
виправляє все це з коробки.

## 🚀 Швидкий старт

```bash
nix run github:varsoug/phonerlite-flake
```

Перший запуск збере пакет (близько хвилини) і запустить PhonerLite. SIP-акаунти, телефонна
книга та журнал дзвінків лежать у `~/.local/share/phonerlite/` — застосунок залишається
повністю переносним. Портативний ZIP вендора постачається разом із флейком, тож збірці не
потрібен доступ до мережі.

## ✨ Можливості

|   |   |
|---|---|
| 🍷 **Wine, вже налаштований** | Окремий 64-бітний префікс, правильний драйвер, виправлення реєстру та ini застосовуються автоматично. |
| 🪟 **Нативні рамки** | KWin/GNOME малюють заголовок — жодних вбудованих кнопок WinXP. |
| 🔤 **Чіткі шрифти** | Повне згладжування шрифтів (аналог ClearType) увімкнено в префіксі. |
| 🖼️ **Нормальний DPI** | За замовчуванням рендерить на 120 PPI, щоб іконки не були грубими; налаштовується. |
| 🗂️ **Ізольований префікс** | Живе в `~/.local/share/phonerlite-prefix`; ваш `~/.wine` не чіпається. |
| 📦 **Без налаштувань** | Один рядок модуля або один `nix run` — без winecfg, winetricks і ручної правки реєстру. |
| 🔌 **Переносний стан** | Акаунти, телефонна книга та логи залишаються в `~/.local/share/phonerlite/`, незалежно від стор. |

## 📦 Встановлення

### Варіант 1 — NixOS-модуль (рекомендовано)

**1.** Додайте вхід у `flake.nix` вашої системи:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # ...ваші інші входи...
    phonerlite.url = "github:varsoug/phonerlite-flake";
  };
```

**2.** Увімкніть модуль:

```nix
  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        # ...ваші інші модулі...
        inputs.phonerlite.nixosModules.default
        { programs.phonerlite.enable = true; }
      ];
    };
  };
```

**3.** Перезберіть і запустіть:

```bash
sudo nixos-rebuild switch --flake /path/to/your/flake#myhost
phonerlite
```

Хочете просто як пакет? Результат той самий:

```nix
{ environment.systemPackages = [ inputs.phonerlite.packages.x86_64-linux.phonerlite ]; }
```

### Варіант 2 — Overlay

```nix
nixpkgs.overlays = [ inputs.phonerlite.overlays.default ];
# далі будь-де в конфігурації:
environment.systemPackages = with pkgs; [ phonerlite ];
```

### Варіант 3 — Без flakes (legacy config)

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
> Home-manager не потрібен — єдиний вхід флейка це `nixpkgs`.

## ⚙️ Налаштування

Масштаб інтерфейсу за замовчуванням 120 PPI (PhonerLite розрахований на 96 PPI і інакше
виглядає грубо). Перевизначається під час виклику пакета:

```nix
pkgs.callPackage ./packages/phonerlite.nix { scalePPI = "96"; }  # або "144"
```

## 🔍 Як це працює

<details>
<summary>Деталі за кожним обхідним рішенням</summary>

**Навіщо окремий префікс.** `PhonerLite.exe` — 64-бітний PE-бінарник. Якщо ваш `~/.wine` це
32-бітний префікс, Wine відмовиться його запускати з «Bad EXE format». Лаунчер тримає свій
префікс у `~/.local/share/phonerlite-prefix` і ніколи не чіпає `~/.wine`.

**Чому `wineWow64Packages.stable`, а не `.wayland`.** У збірці `wayland` взагалі немає
X11-драйвера (`winex11.drv` відсутній), тому застосунок не запускається. У `stable`, `staging`
і `full` є обидва драйвери.

**Чому примусово X11 (`env -u WAYLAND_DISPLAY`).** По-перше, `winewayland.so` не реалізує
протокол `xdg-decoration` — він завжди малює свою рамку в стилі WinXP, а ключ реєстру
`Decorated=Y` діє лише на X11-драйвер. По-друге, у Wayland-драйвері є баг: після згортання вікна
кнопки керування перестають працювати до перезапуску. Через XWayland обидві проблеми зникають,
і заголовок малює композитор.

**Чому портативний ZIP, а не інсталятор.** Вендор постачає портативний ZIP; інсталятор лише
створює ярлики. ZIP розпаковується в nix-стор, лаунчер під час першого запуску копіює його в
`~/.local/share/phonerlite` і запускає звідти — PhonerLite зберігає `sipper.ini`, телефонну
книгу та логи поруч із `.exe`, а шлях у сторі залишається лише для читання.

**Ключі реєстру під час кожного запуску** (ідемпотентно):
- `HKCU\Control Panel\Desktop\Decorated=Y` — віддати рамку вікна віконному менеджеру;
- `FontSmoothing=2`, `FontSmoothingType=2`, `FontSmoothingOrientation=1`,
  `FontSmoothingGamma=0x578` — повне згладжування шрифтів (свіжий префікс рендерить піксельно).
- `LogPixels` навмисно **не** встановлюється: з ним PhonerLite зависає до створення головного
  вікна.

**Правки ini під час кожного запуску** (ідемпотентно): `WindowState=0` (інакше застосунок
відкривається згорнутим — він зберігає цей стан при виході) і `ScaleDefaultPPI=<scalePPI>`
(масштаб інтерфейсу).

**Особливості пакування.** Власний розпакувальник Nix не вміє відкривати ZIP вендора («do not
know how to unpack source archive»), тому `dontUnpack = true`, а розпакування йде в
`installPhase` через `unzip`; ненульовий код повернення через не-ASCII імена ігнорується, а
локалізовані копії ліцензій відкидаються. Іконка витягується з ресурсів `.exe` через
`wrestool`/`icotool`.

**CI.** `.github/workflows/ci.yml` збирає пакет і перевіряє його вміст (лаунчер, desktop-файл,
іконку) на кожен push. ZIP вендора лежить у репозиторії (`packages/PhonerLite64.zip`), бо
пісочниця не може достукатися до phoner.de.

</details>

## 🖥️ Перевірено на

| Компонент | Версія |
| --- | --- |
| ОС | NixOS 26.11 «Zokor» (`nixos-unstable`) |
| DE / WM | KDE Plasma 6.8.1, KWin (сеанс Wayland) |
| Wine | wine-wow64 11.0 (`wineWow64Packages.stable`) |
| PhonerLite | 3.46 (2026-10-12) |

Залізо: AMD Ryzen 7 8845HS (Radeon 780M, драйвер amdgpu), x86_64, 1920x1080 @ 144 Гц.

> [!IMPORTANT]
> Пакет збирається з `wineWow64Packages.stable`, бо у варіанта `wayland` взагалі немає
> X11-драйвера — без нього застосунок не запуститься. На інших DE (GNOME, COSMIC, sway…)
> очікується робота через XWayland, але перевірено лише Plasma 6.8.

## ⬆️ Оновлення PhonerLite

1. Завантажте свіжий `PhonerLite64.zip` зі
   [сторінки завантаження вендора](https://www.phonerlite.de/download_en.htm).
2. Замініть ним `packages/PhonerLite64.zip`.
3. Підніміть `version` у [`packages/phonerlite.nix`](../packages/phonerlite.nix).

ZIP є частиною репозиторію, бо пісочниця GitHub CI не має доступу до вендора.

## 📄 Ліцензія

Сам PhonerLite — freeware із закритим вихідним кодом (див.
[ліцензію вендора](https://www.phonerlite.de/index_en.htm)); вільне використання й
розповсюдження дозволені. Код пакування в цьому репозиторії — MIT.

<div align="center">

Якщо це врятувало вам вечір із winecfg — поставте ⭐

</div>
