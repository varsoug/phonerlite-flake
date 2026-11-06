{
  lib,
  stdenvNoCC,
  wineWow64Packages,
  icoutils,
  makeDesktopItem,
  unzip,
  scalePPI ? "120",
}:

let
  # Checked in next to this file. The vendor ships a portable ZIP and the
  # GitHub CI sandbox cannot reach phoner.de, so the package cannot fetch it.
  src = ./. + "/PhonerLite64.zip";
  pname = "phonerlite";
  version = "3.46";

  desktopItem = makeDesktopItem {
    name = pname;
    desktopName = "PhonerLite";
    comment = "SIP softphone (via Wine)";
    exec = pname;
    icon = pname;
    categories = [
      "Network"
      "Telephony"
    ];
  };
in
stdenvNoCC.mkDerivation {
  inherit pname version;

  inherit src;

  nativeBuildInputs = [ unzip ];

  # Nix cannot unpack this archive itself ("do not know how to unpack source
  # archive"), so installPhase extracts it. unzip exits non-zero on the
  # ZIP's non-ASCII member names, hence `|| true`.
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/phonerlite $out/share/applications
    cd $out/share/phonerlite
    unzip -j -o ${src} || true
    # The vendor's license copies under non-ASCII names are not shipped;
    # the ASCII license.txt is.
    # Per-language license copies come out as #U... escapes
    # (licen#U00e7a.txt, #U041b...txt); the ASCII license.txt is enough.
    for f in *.txt; do
      case "$f" in
        license.txt|licencia.txt|licenz.txt) ;;
        *) rm -f "$f" ;;
      esac
    done

    ${icoutils}/bin/wrestool -x -t 14 -o PhonerLite.ico PhonerLite.exe
    ${icoutils}/bin/icotool -x -o PhonerLite.png PhonerLite.ico
    install -Dm644 PhonerLite.png $out/share/icons/hicolor/256x256/apps/phonerlite.png

    cp ${desktopItem}/share/applications/phonerlite.desktop $out/share/applications/

    mkdir -p $out/bin
    cat > $out/bin/phonerlite <<EOF
    #!${stdenvNoCC.shell}
    set -e
    appdir="\$HOME/.local/share/phonerlite"
    # A dedicated 64-bit prefix: the user's default ~/.wine may be a 32-bit
    # installation and refuses to run the 64-bit PhonerLite.exe.
    export WINEPREFIX="\$HOME/.local/share/phonerlite-prefix"
    mkdir -p "\$appdir"
    if [ ! -f "\$appdir/PhonerLite.exe" ]; then
      cp -r --no-preserve=mode "$out/share/phonerlite/." "\$appdir/"
    fi
    WINE=${wineWow64Packages.stable}/bin/wine
    if [ ! -d "\$WINEPREFIX/drive_c" ]; then
      ${wineWow64Packages.stable}/bin/wineboot -u
    fi
    # A fresh prefix renders pixelated bitmap fonts; enable full smoothing.
    ${wineWow64Packages.stable}/bin/wine reg add 'HKCU\\Control Panel\\Desktop' /v FontSmoothing /d 2 /f >/dev/null 2>&1 || true
    ${wineWow64Packages.stable}/bin/wine reg add 'HKCU\\Control Panel\\Desktop' /v FontSmoothingOrientation /d 1 /f >/dev/null 2>&1 || true
    ${wineWow64Packages.stable}/bin/wine reg add 'HKCU\\Control Panel\\Desktop' /v FontSmoothingType /d 2 /f >/dev/null 2>&1 || true
    ${wineWow64Packages.stable}/bin/wine reg add 'HKCU\\Control Panel\\Desktop' /v FontSmoothingGamma /d 0x578 /f >/dev/null 2>&1 || true
    # PhonerLite saves WindowState=1 (minimized) on exit and restores it on
    # the next start; force a normal window before every launch.
    sed -i 's/^WindowState=.*/WindowState=0/' "\$appdir/sipper.ini" 2>/dev/null || true
    # Keep the main window in the task list. With HideTaskbarIcon=1 the app
    # lives only in the system tray, and a tray that is hidden or covered
    # (XFCE panels are 21 px tall) leaves no way to raise or quit it.
    for d in PhonerLite.ini sipper.ini; do
      f="\$appdir/\$d"
      [ -f "\$f" ] || continue
      if grep -q '^HideTaskbarIcon=' "\$f"; then
        sed -i 's/^HideTaskbarIcon=.*/HideTaskbarIcon=0/' "\$f"
      else
        sed -i 's/^ShowSystray=.*/&\nHideTaskbarIcon=0/' "\$f"
      fi
    done
    # Render at 120 PPI so the 96-PPI icons are not upscaled by the
    # compositor. LogPixels is deliberately not set: with it the app hangs
    # before creating its main window.
    sed -i 's/^ScaleDefaultPPI=.*/ScaleDefaultPPI=${scalePPI}/' "\$appdir/sipper.ini" 2>/dev/null || true
    # Window frames: write Decorated=Y, then stop the wineserver of any
    # earlier launch so the app's server starts with the new value. A
    # leftover server keeps the old Decorated setting and leaves the
    # incoming-call popup with an extra WinXP-style frame.
    "\$WINE" reg add 'HKCU\\Control Panel\\Desktop' /v Decorated /d Y /f >/dev/null 2>&1 || true
    ${wineWow64Packages.stable}/bin/wineserver -k >/dev/null 2>&1 || true
    ${wineWow64Packages.stable}/bin/wineserver -w >/dev/null 2>&1 || true
    exec env -u WAYLAND_DISPLAY ${wineWow64Packages.stable}/bin/wine "\$appdir/PhonerLite.exe" "\$@"
    EOF
    chmod +x $out/bin/phonerlite

    runHook postInstall
  '';

  meta = {
    description = "PhonerLite SIP softphone (Windows build running on Wine)";
    homepage = "https://www.phonerlite.de";
    license = lib.licenses.unfreeRedistributable;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
