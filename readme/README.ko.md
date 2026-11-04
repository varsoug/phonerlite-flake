<div align="center">

[🇬🇧 English](../README.md) | [🇨🇳 简体中文](README.zh-CN.md) | [🇪🇸 Español](README.es.md) | [🇧🇷 Português](README.pt-BR.md) | [🇩🇪 Deutsch](README.de.md) | [🇫🇷 Français](README.fr.md) | [🇯🇵 日本語](README.ja.md) | **🇰🇷 한국어** | [🇷🇺 Русский](README.ru.md) | [🇺🇦 Українська](README.uk.md)

# NixOS용 PhonerLite

<img src="../docs/screenshot.png" width="420" alt="PhonerLite running through Wine">

**Nix용으로 패키징된 무료 SIP 소프트폰 — 데스크톱 통합의 모든 함정을 미리 해결한 상태로 Wine에서 실행됩니다.**

[![CI](https://img.shields.io/github/actions/workflow/status/varsoug/phonerlite-flake/ci.yml?style=flat-square&label=ci)](https://github.com/varsoug/phonerlite-flake/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/varsoug/phonerlite-flake?style=flat-square)](https://github.com/varsoug/phonerlite-flake/releases)
[![License](https://img.shields.io/github/license/varsoug/phonerlite-flake?style=flat-square)](../LICENSE)
[![NixOS unstable](https://img.shields.io/badge/nixos-unstable-blue.svg?style=flat-square&logo=nixos)](https://nixos.org)
[![Wine](https://img.shields.io/badge/wine-wow64%2011.0-732727?style=flat-square&logo=wine)](https://www.winehq.org)

[**빠른 시작**](#-빠른-시작) ·
[기능](#-기능) ·
[설치](#-설치) ·
[동작 방식](#-동작-방식) ·
[테스트 환경](#-테스트-환경)

</div>

---

[PhonerLite](https://www.phonerlite.de)는 Windows용 무료(프리웨어) SIP 소프트폰입니다. 이
flake는 이를 NixOS / Nix on Linux용으로 패키징하고 Wine 위에서 **올바른 방식으로** 실행합니다.
네이티브 창 장식, 안티에일리어싱된 글꼴, 적절한 DPI, 최소화에서 제대로 돌아오는 창까지.

`pkgs.wine`만 설치하고 `wine PhonerLite.exe`를 실행하면 몇 분 안에 벽에 부딪힙니다.
*"Bad EXE format"*, 깨져 보이는 글꼴, WinXP 스타일 창 버튼, 최소화 후 다시 돌아오지 않는 창,
그리고 항상 최소화 상태로 열리는 앱. 이 패키지는 그 모든 것을 처음부터 해결합니다.

## 👥 누구를 위한 것인가

- **NixOS 또는 Nix**(flakes 사용 여부 무관)를 쓰면서 Linux에서 돌아가는 SIP 소프트폰이 필요한 사람.
- **Wayland 기반 KDE Plasma**를 쓰는 사람 — `wine PhonerLite.exe`가 보통 여기서 실패합니다.
- **수동 설정을 하기 싫은** 사람: winecfg, winetricks, 레지스트리 편집이 필요 없습니다.
- 대체품이 아니라 **벤더 배포판 빌드**(프리웨어, 소스 비공개)를 원하는 사람.

## 🚀 빠른 시작

```bash
nix run github:varsoug/phonerlite-flake
```

첫 실행 시 패키지를 빌드하고(약 1분) PhonerLite를 시작합니다. SIP 계정, 전화번호부, 통화
기록은 `~/.local/share/phonerlite/`에 저장되어 앱은 완전히 포터블하게 유지됩니다. 벤더의
포터블 ZIP이 flake에 포함되어 있어 빌드에 네트워크가 필요 없습니다.

## ✨ 기능

|   |   |
|---|---|
| 🍷 **미리 설정된 Wine** | 전용 64비트 프리픽스, 올바른 드라이버 선택, 레지스트리와 ini 수정 자동 적용. |
| 🪟 **네이티브 창 장식** | KWin/GNOME이 제목 표시줄을 그립니다 — 내장 WinXP 버튼 없음. |
| 🔤 **선명한 글꼴** | 프리픽스에서 전체 글꼴 스무딩(ClearType 상당)을 활성화합니다. |
| 🖼️ **적절한 DPI** | 아이콘이 뭉개지지 않도록 기본 120 PPI로 렌더링하며 설정 가능합니다. |
| 🗂️ **분리된 프리픽스** | `~/.local/share/phonerlite-prefix`에 위치하며 `~/.wine`은 건드리지 않습니다. |
| 📦 **설정 불필요** | 모듈 한 줄 또는 `nix run` 한 번 — winecfg, winetricks, 수동 레지스트리 편집 없음. |
| 🔌 **포터블 상태** | 계정, 전화번호부, 로그가 store와 무관하게 `~/.local/share/phonerlite/`에 유지됩니다. |

## 📦 설치

### 방법 1 — NixOS 모듈 (권장)

**1.** 시스템의 `flake.nix`에 input을 추가합니다.

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # ...나머지 input...
    phonerlite.url = "github:varsoug/phonerlite-flake";
  };
```

**2.** 모듈을 활성화합니다.

```nix
  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        # ...나머지 모듈...
        inputs.phonerlite.nixosModules.default
        { programs.phonerlite.enable = true; }
      ];
    };
  };
```

**3.** 다시 빌드하고 실행합니다.

```bash
sudo nixos-rebuild switch --flake /path/to/your/flake#myhost
phonerlite
```

일반 패키지로 쓰고 싶다면 결과는 같습니다.

```nix
{ environment.systemPackages = [ inputs.phonerlite.packages.x86_64-linux.phonerlite ]; }
```

### 방법 2 — Overlay

```nix
nixpkgs.overlays = [ inputs.phonerlite.overlays.default ];
# 이후 설정 어디에서든:
environment.systemPackages = with pkgs; [ phonerlite ];
```

### 방법 3 — Flakes 없이 (레거시 설정)

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
> home-manager는 필요 없습니다 — flake의 유일한 input은 `nixpkgs`입니다.

## ⚙️ 설정

UI 배율은 기본 120 PPI입니다(PhonerLite는 96 PPI 기준이라 그대로 두면 뭉개 보입니다).
패키지를 호출할 때 덮어쓸 수 있습니다.

```nix
pkgs.callPackage ./packages/phonerlite.nix { scalePPI = "96"; }  # 또는 "144"
```

## 🔍 동작 방식

<details>
<summary>각 우회 방법의 배경</summary>

**왜 전용 프리픽스인가.** `PhonerLite.exe`는 64비트 PE 바이너리입니다. `~/.wine`이 32비트
프리픽스라면 Wine은 "Bad EXE format"으로 실행을 거부합니다. 런처는
`~/.local/share/phonerlite-prefix`에 자체 프리픽스를 두고 `~/.wine`은 절대 건드리지 않습니다.

**왜 `wineWow64Packages.stable`이고 `.wayland`가 아닌가.** Wine의 `wayland` 빌드에는 X11
드라이버가 아예 없어(`winex11.drv` 부재) 앱이 시작되지 않습니다. `stable`, `staging`, `full`
에는 두 드라이버가 모두 들어 있습니다.

**왜 X11을 강제하는가(`env -u WAYLAND_DISPLAY`).** 첫째, `winewayland.so`는
`xdg-decoration` 프로토콜을 구현하지 않아 항상 자체 WinXP 스타일 제목 표시줄을 그리며,
레지스트리 키 `Decorated=Y`는 X11 드라이버에만 적용됩니다. 둘째, Wayland 드라이버에는
최소화하면 재시작 전까지 창 버튼이 동작하지 않는 버그가 있습니다. XWayland를 거치면 두
문제가 모두 사라지고 컴포지터가 일반 제목 표시줄을 그립니다.

**왜 설치 프로그램이 아니라 포터블 ZIP인가.** 벤더는 포터블 ZIP을 배포하고 설치 프로그램은
바로가기만 만듭니다. ZIP은 nix store에 풀리고, 런처가 첫 실행 시
`~/.local/share/phonerlite`로 복사해 그곳에서 실행합니다. PhonerLite는 `sipper.ini`,
전화번호부, 로그를 `.exe` 옆에 저장하고 store 경로는 읽기 전용으로 남습니다.

**실행할 때마다 쓰는 레지스트리 키**(멱등):
- `HKCU\Control Panel\Desktop\Decorated=Y` — 창 장식을 창 관리자에 맡김;
- `FontSmoothing=2`, `FontSmoothingType=2`, `FontSmoothingOrientation=1`,
  `FontSmoothingGamma=0x578` — 전체 글꼴 안티에일리어싱(새 프리픽스는 글꼴이 깨져 보입니다).
- `LogPixels`는 의도적으로 **설정하지 않습니다**: 설정하면 PhonerLite가 메인 창을 만들기 전에
  멈춥니다.

**실행할 때마다 적용하는 ini 수정**(멱등): `WindowState=0`(그렇지 않으면 최소화 상태로
열립니다 — 종료 시 그 상태를 저장합니다)과 `ScaleDefaultPPI=<scalePPI>`(UI 배율).

**패키징 특이사항.** Nix 자체 압축 해제기는 벤더 ZIP을 열지 못합니다("do not know how to
unpack source archive"). 그래서 `dontUnpack = true`로 두고 `installPhase`에서 `unzip`으로
풉니다. 비ASCII 파일 이름 때문에 발생하는 0이 아닌 종료 코드는 무시하고, 언어별 라이선스
사본은 삭제합니다. 아이콘은 `.exe` 리소스에서 `wrestool`/`icotool`로 추출합니다.

**CI.** `.github/workflows/ci.yml`이 push마다 패키지를 빌드하고 산출물(런처, desktop 파일,
아이콘)을 검사합니다. 벤더 ZIP을 저장소에 포함한 이유는(`packages/PhonerLite64.zip`)
샌드박스가 phoner.de에 접속할 수 없기 때문입니다.

</details>

## 🖥️ 테스트 환경

| 구성 요소 | 버전 |
| --- | --- |
| OS | NixOS 26.11 «Zokor»(`nixos-unstable`) |
| DE / WM | KDE Plasma 6.8.1, KWin(Wayland 세션) |
| Wine | wine-wow64 11.0(`wineWow64Packages.stable`) |
| PhonerLite | 3.46(2026-10-12) |

하드웨어: AMD Ryzen 7 8845HS(Radeon 780M, amdgpu 드라이버), x86_64, 1920x1080 @ 144 Hz.

> [!IMPORTANT]
> 패키지는 `wineWow64Packages.stable`로 빌드합니다. `wayland` 버전에는 X11 드라이버가 전혀
> 없어 그것 없이는 앱이 시작되지 않기 때문입니다. 다른 데스크톱 환경(GNOME, COSMIC, sway 등)
> 에서도 XWayland를 통해 동작할 것으로 예상하지만, 검증된 것은 Plasma 6.8뿐입니다.

## ⬆️ PhonerLite 업데이트

1. [벤더 다운로드 페이지](https://www.phonerlite.de/download_en.htm)에서 새
   `PhonerLite64.zip`을 받습니다.
2. `packages/PhonerLite64.zip`을 그것으로 교체합니다.
3. [`packages/phonerlite.nix`](../packages/phonerlite.nix)의 `version`을 올립니다.

ZIP이 저장소에 포함된 이유는 GitHub CI 샌드박스가 벤더에 접속할 수 없기 때문입니다.

## 📄 라이선스

이 저장소의 패키징 코드는 [MIT](../LICENSE)입니다. PhonerLite 자체는 해당되지 않습니다: 벤더의 독점 프리웨어이며([벤더 라이선스](https://www.phonerlite.de/index_en.htm) 참조) 오프라인 빌드를 위해 `packages/PhonerLite64.zip`에 그대로 포함되어 있습니다.

<div align="center">

winecfg로 보낼 저녁을 아꼈다면 — ⭐ 부탁드립니다

</div>
