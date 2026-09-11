{
    callPackage,
    lib,
    stdenv,
    pname ? "telegram-desktop",
    unwrapped ? callPackage ./unwrapped.nix {inherit stdenv;},
    qt6,
    kdePackages,
    wrapGAppsHook3,
    geoclue2,
    glib-networking,
    webkitgtk_4_1,
    withWebkit ? true,
}:
stdenv.mkDerivation (finalAttrs: {
    inherit pname;
    inherit (finalAttrs.unwrapped) version meta passthru;

    inherit unwrapped;

    nativeBuildInputs =
        [
            qt6.wrapQtAppsHook
        ]
        ++ lib.optionals withWebkit [
            wrapGAppsHook3
        ];

    buildInputs =
        [
            qt6.qtbase
            qt6.qtimageformats
            qt6.qtsvg
            kdePackages.kimageformats
            qt6.qtwayland
            qt6.qtlottie
        ]
        ++ lib.optionals withWebkit [
            glib-networking
        ];

    qtWrapperArgs = lib.optionals withWebkit [
        "--prefix"
        "LD_LIBRARY_PATH"
        ":"
        (lib.makeLibraryPath [
            geoclue2
            webkitgtk_4_1
        ])
    ];

    dontUnpack = true;
    dontWrapGApps = true;

    installPhase = ''
        runHook preInstall
        cp -r "$unwrapped" "$out"
        runHook postInstall
    '';

    preFixup = lib.optionalString withWebkit ''
        qtWrapperArgs+=("''${gappsWrapperArgs[@]}")
    '';

    postFixup = ''
        substituteInPlace $out/share/dbus-1/services/* \
          --replace-fail "$unwrapped" "$out"
    '';
})
