<div align="center">

[🇬🇧 English](../README.md) | [🇨🇳 简体中文](README.zh-CN.md) | [🇪🇸 Español](README.es.md) | **🇧🇷 Português** | [🇩🇪 Deutsch](README.de.md) | [🇫🇷 Français](README.fr.md) | [🇯🇵 日本語](README.ja.md) | [🇰🇷 한국어](README.ko.md) | [🇷🇺 Русский](README.ru.md) | [🇺🇦 Українська](README.uk.md)

# PhonerLite para NixOS

<img src="../docs/screenshot.png" width="420" alt="PhonerLite running through Wine">

**Um softphone SIP gratuito, empacotado para Nix — roda no Wine com todos os problemas de integração com a área de trabalho já resolvidos.**

[![CI](https://img.shields.io/github/actions/workflow/status/varsoug/phonerlite-flake/ci.yml?style=flat-square&label=ci)](https://github.com/varsoug/phonerlite-flake/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/varsoug/phonerlite-flake?style=flat-square)](https://github.com/varsoug/phonerlite-flake/releases)
[![License](https://img.shields.io/github/license/varsoug/phonerlite-flake?style=flat-square)](../LICENSE)
[![NixOS unstable](https://img.shields.io/badge/nixos-unstable-blue.svg?style=flat-square&logo=nixos)](https://nixos.org)
[![Wine](https://img.shields.io/badge/wine-wow64%2011.0-732727?style=flat-square&logo=wine)](https://www.winehq.org)

[**Início rápido**](#-início-rápido) ·
[Recursos](#-recursos) ·
[Instalação](#-instalação) ·
[Como funciona](#-como-funciona) ·
[Testado em](#-testado-em)

</div>

---

O [PhonerLite](https://www.phonerlite.de) é um softphone SIP gratuito (freeware) para Windows.
Este flake o empacota para NixOS / Nix no Linux e o executa pelo Wine **como ele deve rodar**:
decoração de janela nativa, fontes suavizadas, DPI razoável, uma janela que sobrevive a
minimizar.

Se você apenas instalar `pkgs.wine` e rodar `wine PhonerLite.exe`, vai bater de frente com um
muro em minutos: *«Bad EXE format»*, fontes pixeladas, botões de janela estilo WinXP, uma janela
que nunca volta depois de minimizada e um app que sempre reabre minimizado. Este pacote resolve
tudo isso de imediato.

## 👥 Para quem é isso?

- Você usa **NixOS ou Nix** (com ou sem flakes) e precisa de um softphone SIP no Linux.
- Está no **KDE Plasma com Wayland** — exatamente onde `wine PhonerLite.exe` costuma falhar.
- Não quer **configurar nada à mão**: sem winecfg, winetricks ou registro.
- Quer o **build do fabricante** do PhonerLite (freeware, código fechado), não um substituto.

## 🚀 Início rápido

```bash
nix run github:varsoug/phonerlite-flake
```

A primeira execução compila o pacote (cerca de um minuto) e inicia o PhonerLite. Contas SIP,
agenda e histórico ficam em `~/.local/share/phonerlite/` — o app continua totalmente portátil.
O ZIP portátil do fabricante vem junto com o flake, então a build não precisa de rede.

## ✨ Recursos

|   |   |
|---|---|
| 🍷 **Wine já ajustado** | Prefixo 64 bits dedicado, driver correto, correções de registro e ini automáticas. |
| 🪟 **Decoração nativa** | KWin/GNOME desenham a barra de título — sem botões WinXP embutidos. |
| 🔤 **Fontes nítidas** | Suavização completa de fontes (equivale ao ClearType) ativada no prefixo. |
| 🖼️ **DPI razoável** | Renderiza a 120 PPI por padrão para os ícones não ficarem toscos; configurável. |
| 🗂️ **Prefixo isolado** | Fica em `~/.local/share/phonerlite-prefix`; seu `~/.wine` nunca é tocado. |
| 📦 **Zero configuração** | Uma linha de módulo ou um `nix run` — sem winecfg, winetricks ou edição manual do registro. |
| 🔌 **Estado portátil** | Contas, agenda e logs ficam em `~/.local/share/phonerlite/`, fora do store. |

## 📦 Instalação

### Opção 1 — Módulo NixOS (recomendado)

**1.** Adicione o input ao `flake.nix` do seu sistema:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # ...seus outros inputs...
    phonerlite.url = "github:varsoug/phonerlite-flake";
  };
```

**2.** Ative o módulo:

```nix
  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        # ...seus outros módulos...
        inputs.phonerlite.nixosModules.default
        { programs.phonerlite.enable = true; }
      ];
    };
  };
```

**3.** Reconstrua e inicie:

```bash
sudo nixos-rebuild switch --flake /path/to/your/flake#myhost
phonerlite
```

Prefere só o pacote? Mesmo resultado:

```nix
{ environment.systemPackages = [ inputs.phonerlite.packages.x86_64-linux.phonerlite ]; }
```

### Opção 2 — Overlay

```nix
nixpkgs.overlays = [ inputs.phonerlite.overlays.default ];
# e depois, em qualquer lugar da sua configuração:
environment.systemPackages = with pkgs; [ phonerlite ];
```

### Opção 3 — Sem flakes (configuração legacy)

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
> Home-manager não é necessário — o único input do flake é `nixpkgs`.

## ⚙️ Configuração

A escala da interface é de 120 PPI por padrão (o PhonerLite é pensado para 96 PPI e fica tosco
caso contrário). Pode ser sobrescrita ao chamar o pacote:

```nix
pkgs.callPackage ./packages/phonerlite.nix { scalePPI = "96"; }  # ou "144"
```

## 🔍 Como funciona

<details>
<summary>Os detalhes por trás de cada contorno</summary>

**Por que um prefixo próprio.** `PhonerLite.exe` é um binário PE de 64 bits. Se seu `~/.wine` for
um prefixo de 32 bits, o Wine se recusa a executá-lo com «Bad EXE format». O launcher mantém seu
próprio prefixo em `~/.local/share/phonerlite-prefix` e nunca toca em `~/.wine`.

**Por que `wineWow64Packages.stable` e não `.wayland`.** A variante `wayland` do Wine não traz
nenhum driver X11 (`winex11.drv` ausente), então o app não inicia. `stable`, `staging` e `full`
incluem ambos.

**Por que forçar X11 (`env -u WAYLAND_DISPLAY`).** Primeiro, `winewayland.so` não implementa o
protocolo `xdg-decoration` — ele sempre desenha sua própria barra de título estilo WinXP, e a
chave de registro `Decorated=Y` só afeta o driver X11. Segundo, o driver Wayland tem um bug: ao
minimizar, os botões da janela param de funcionar até reiniciar. Pelo XWayland os dois problemas
somem e o compositor desenha uma barra de título normal.

**Por que o ZIP portátil e não o instalador.** O fabricante fornece um ZIP portátil; o instalador
só cria atalhos. O ZIP é extraído no store do Nix, o launcher o copia para
`~/.local/share/phonerlite` na primeira execução e inicia dali — o PhonerLite mantém
`sipper.ini`, a agenda e os logs junto ao `.exe`, enquanto o caminho do store fica somente leitura.

**Chaves de registro a cada execução** (idempotente):
- `HKCU\Control Panel\Desktop\Decorated=Y` — entregar a decoração ao gerenciador de janelas;
- `FontSmoothing=2`, `FontSmoothingType=2`, `FontSmoothingOrientation=1`,
  `FontSmoothingGamma=0x578` — suavização total de fontes (um prefixo novo renderiza pixelado).
- `LogPixels` é deliberadamente **não** definido: com ele, o PhonerLite trava antes de criar a
  janela principal.

**Correções de ini a cada execução** (idempotente): `WindowState=0` (senão o app abre
minimizado — ele salva esse estado ao sair) e `ScaleDefaultPPI=<scalePPI>` (escala da interface).

**Detalhes de empacotamento.** O desempacotador do próprio Nix não abre o ZIP do fabricante («do
not know how to unpack source archive»), por isso `dontUnpack = true` e a extração acontece em
`installPhase` via `unzip`; o código de saída diferente de zero por causa dos nomes não ASCII é
ignorado, e as cópias de licença por idioma são descartadas. O ícone é extraído dos recursos do
`.exe` com `wrestool`/`icotool`.

**CI.** `.github/workflows/ci.yml` compila o pacote e verifica suas saídas (launcher, arquivo
desktop, ícone) a cada push. O ZIP do fabricante está versionado
(`packages/PhonerLite64.zip`) porque a sandbox não alcança phoner.de.

</details>

## 🖥️ Testado em

| Componente | Versão |
| --- | --- |
| SO | NixOS 26.11 «Zokor» (`nixos-unstable`) |
| DE / WM | KDE Plasma 6.8.1, KWin (sessão Wayland) |
| Wine | wine-wow64 11.0 (`wineWow64Packages.stable`) |
| PhonerLite | 3.46 (2026-10-12) |

Hardware: AMD Ryzen 7 8845HS (Radeon 780M, driver amdgpu), x86_64, 1920x1080 @ 144 Hz.

> [!IMPORTANT]
> O pacote é compilado contra `wineWow64Packages.stable` porque a variante `wayland` não tem
> driver X11 — sem ele o app não inicia. Em outras DEs (GNOME, COSMIC, sway…) espera-se que
> funcione via XWayland, mas só o Plasma 6.8 foi verificado.

## ⬆️ Atualizando o PhonerLite

1. Baixe o novo `PhonerLite64.zip` na
   [página de download do fabricante](https://www.phonerlite.de/download_en.htm).
2. Substitua `packages/PhonerLite64.zip` por ele.
3. Suba a `version` em [`packages/phonerlite.nix`](../packages/phonerlite.nix).

O ZIP faz parte do repositório porque a sandbox do CI do GitHub não tem acesso ao fabricante.

## 📄 Licença

O código de empacotamento deste repositório é [MIT](../LICENSE). O PhonerLite não está coberto: é freeware proprietário do fabricante (veja a [licença do fabricante](https://www.phonerlite.de/index_en.htm)), incluído como está em `packages/PhonerLite64.zip` para builds offline.

<div align="center">

Se isso te poupou uma noite de winecfg — considere dar uma ⭐

</div>
