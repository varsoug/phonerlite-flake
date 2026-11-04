# PhonerLite (https://www.phonerlite.de) — freeware SIP softphone for
# Windows, packaged to run on NixOS/Nix through Wine with the desktop-
# integration pitfalls already solved:
#
#   * 64-bit prefix: PhonerLite.exe is a 64-bit PE, so a dedicated WoW64
#     prefix is created (~/.local/share/phonerlite-prefix). The user's
#     default ~/.wine may be a 32-bit installation and would refuse the
#     exe with "Bad EXE format".
#   * X11 driver, not Wayland: wineWow64Packages.wayland ships no
#     winex11.drv at all, and winewayland.so has no xdg-decoration support
#     (always draws its own Windows-style title bar) plus a minimize bug
#     that kills the window controls until restart. The launcher therefore
#     unsets WAYLAND_DISPLAY so Wine picks winex11 and KWin decorates the
#     window natively.
#   * Registry tuning on every launch (idempotent): Decorated=Y so KWin
#     draws the title bar, FontSmoothing* so text is not pixelated.
#     LogPixels is deliberately NOT touched — setting it makes PhonerLite
#     hang before creating its main window.
#   * ini fixes on every launch (idempotent): WindowState=0 so it does not
#     reopen minimized (the app saves the minimized state on exit and
#     restores it), ScaleDefaultPPI=120 to render crisp at 125 % instead
#     of upscaling 96 PPI bitmaps.
#
# The vendor distributes a portable ZIP (the installer only creates
# shortcuts), so the ZIP is unpacked into the store and the launcher copies
# it to ~/.local/share/phonerlite on first run and starts it from there —
# PhonerLite keeps sipper.ini, its phone book and logs next to the .exe,
# and the store path is read-only.
#
# To bump the version: download the new PhonerLite64.zip from
# https://www.phonerlite.de/download_en.htm, update `version` and `hash`.
{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  # Must be a build that includes winex11.drv (wineWow64Packages.wayland
  # does NOT — it is wayland-only). `stable`/`staging`/`full` all work.
  wineWow64Packages,
  icoutils,
  makeDesktopItem,
  # Render the UI at this PPI (default 96*1.25). Set to 96 to disable.
  scalePPI ? "120",
}:

let
  # The vendor serves the ZIP from an unversioned "latest" URL; the hash
  # pins the 3.46 (2026-10-12) build.
  src = fetchurl {
    url = "https://www.phoner.de/PhonerLite64.zip";
    hash = "sha256-IZRA39BdebF5vzf08b/tPDlaNph5Hdup0/tP+BqmgYs=";
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "phonerlite";
  version = "3.46";

  inherit src;

  nativeBuildInputs = [
    unzip
    icoutils
  ];

  # Default unpackPhase cannot handle the zip (non-ASCII member names);
  # extraction happens in installPhase with `unzip -j $src`.
  dontUnpack = true;

  desktopItem = makeDesktopItem {
    name = "phonerlite";
    desktopName = "PhonerLite";
    comment = "SIP softphone (via Wine)";
    exec = "phonerlite";
    icon = "phonerlite";
    categories = [
      "Network"
      "Telephony"
    ];
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/phonerlite $out/share/icons/hicolor/256x256/apps
    # unzip exits nonzero on the zip's non-ASCII member-name warnings; the
    # files themselves extract fine, so don't let the warnings abort the build.
    unzip -j -o $src -d $out/share/phonerlite || true

    wrestool -x -t 14 -o . $out/share/phonerlite/PhonerLite.exe
    # The exe carries a group icon; icotool's first png is the largest one.
    icotool -x -o . phonerlite*.ico 2>/dev/null || true
    png=$(ls -S phonerlite*.png 2>/dev/null | head -1)
    if [ -n "$png" ]; then
      cp "$png" $out/share/icons/hicolor/256x256/apps/phonerlite.png
    fi

    cat > $out/bin/phonerlite <<EOF
    #!${stdenvNoCC.shell}
    set -e
    appdir="\$HOME/.local/share/phonerlite"
    export WINEPREFIX="\$HOME/.local/share/phonerlite-prefix"
    mkdir -p "\$appdir"
    if [ ! -f "\$appdir/PhonerLite.exe" ]; then
      cp -r --no-preserve=mode "$out/share/phonerlite/." "\$appdir/"
    fi
    if [ ! -d "\$WINEPREFIX/drive_c" ]; then
      ${wineWow64Packages.stable}/bin/wineboot -u
    fi
    # KWin-decorated windows + antialiased fonts (see the header comment).
    ${wineWow64Packages.stable}/bin/wine reg add 'HKCU\\Control Panel\\Desktop' /v Decorated /d Y /f >/dev/null 2>&1 || true
    ${wineWow64Packages.stable}/bin/wine reg add 'HKCU\\Control Panel\\Desktop' /v FontSmoothing /d 2 /f >/dev/null 2>&1 || true
    ${wineWow64Packages.stable}/bin/wine reg add 'HKCU\\Control Panel\\Desktop' /v FontSmoothingOrientation /d 1 /f >/dev/null 2>&1 || true
    ${wineWow64Packages.stable}/bin/wine reg add 'HKCU\\Control Panel\\Desktop' /v FontSmoothingType /d 2 /f >/dev/null 2>&1 || true
    ${wineWow64Packages.stable}/bin/wine reg add 'HKCU\\Control Panel\\Desktop' /v FontSmoothingGamma /d 0x578 /f >/dev/null 2>&1 || true
    # Never reopen minimized; render at ${scalePPI} PPI.
    sed -i 's/^WindowState=.*/WindowState=0/' "\$appdir/PhonerLite.ini" 2>/dev/null || true
    sed -i 's/^ScaleDefaultPPI=.*/ScaleDefaultPPI=${scalePPI}/' "\$appdir/PhonerLite.ini" 2>/dev/null || true
    exec env -u WAYLAND_DISPLAY ${wineWow64Packages.stable}/bin/wine "\$appdir/PhonerLite.exe" "\$@"
    EOF
    chmod +x $out/bin/phonerlite

    install -Dm644 ${desktopItem}/share/applications/phonerlite.desktop \
      $out/share/applications/phonerlite.desktop

    runHook postInstall
  '';

  meta = {
    description = "PhonerLite SIP softphone (Windows build running on Wine)";
    homepage = "https://www.phonerlite.de";
    license = lib.licenses.unfreeRedistributable;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "phonerlite";
  };
}
