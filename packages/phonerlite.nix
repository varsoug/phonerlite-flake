{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  wineWow64Packages,
  icoutils,
  makeDesktopItem,
  scalePPI ? "120",
}:

let
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
    unzip -j -o $src -d $out/share/phonerlite || true

    wrestool -x -t 14 -o . $out/share/phonerlite/PhonerLite.exe
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
    ${wineWow64Packages.stable}/bin/wine reg add 'HKCU\\Control Panel\\Desktop' /v Decorated /d Y /f >/dev/null 2>&1 || true
    ${wineWow64Packages.stable}/bin/wine reg add 'HKCU\\Control Panel\\Desktop' /v FontSmoothing /d 2 /f >/dev/null 2>&1 || true
    ${wineWow64Packages.stable}/bin/wine reg add 'HKCU\\Control Panel\\Desktop' /v FontSmoothingOrientation /d 1 /f >/dev/null 2>&1 || true
    ${wineWow64Packages.stable}/bin/wine reg add 'HKCU\\Control Panel\\Desktop' /v FontSmoothingType /d 2 /f >/dev/null 2>&1 || true
    ${wineWow64Packages.stable}/bin/wine reg add 'HKCU\\Control Panel\\Desktop' /v FontSmoothingGamma /d 0x578 /f >/dev/null 2>&1 || true
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
