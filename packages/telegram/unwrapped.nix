{
    lib,
    stdenv,
    fetchFromGitHub,
    callPackage,
    pkg-config,
    cmake,
    ninja,
    python3,
    qt6,
    kdePackages,
    tdlib,
    tg_owt ? callPackage ./tg_owt.nix {inherit stdenv;},
    lz4,
    xxhash,
    ffmpeg_6,
    pangocairo,
    protobuf,
    openal-soft,
    minizip-ng-compat,
    range-v3,
    tl-expected,
    hunspell,
    gobject-introspection,
    rnnoise,
    microsoft-gsl,
    boost,
    ada,
    cmark-gfm,
    nix-update-script,
}:
# Main reference:
# - This package was originally based on the Arch package but all patches are now upstreamed:
#   https://git.archlinux.org/svntogit/community.git/tree/trunk/PKGBUILD?h=packages/telegram-desktop
# Other references that could be useful:
# - https://git.alpinelinux.org/aports/tree/testing/telegram-desktop/APKBUILD
# - https://github.com/void-linux/void-packages/blob/master/srcpkgs/telegram-desktop/template
stdenv.mkDerivation (finalAttrs: {
    pname = "telegram-desktop-unwrapped";
    version = "7.2.8";

    src = fetchFromGitHub {
        owner = "telegramdesktop";
        repo = "tdesktop";
        rev = "v7.2.8";
        fetchSubmodules = true;
        hash = "sha256-Hhx65dqKlsoLvh7lEWYxnIiXFFd0qrDKpYYsHdhzqnk=";
    };

    nativeBuildInputs = [
        pkg-config
        cmake
        ninja
        python3
        qt6.qtshadertools
        gobject-introspection
    ];

    buildInputs = [
        qt6.qtbase
        qt6.qtsvg
        lz4
        xxhash
        ffmpeg_6
        openal-soft
        minizip-ng-compat
        range-v3
        tl-expected
        rnnoise
        tg_owt
        pangocairo
        microsoft-gsl
        boost
        ada
        cmark-gfm
        (tdlib.override {tde2eOnly = true;})
        protobuf
        qt6.qtwayland
        kdePackages.kcoreaddons
        hunspell
    ];

    dontWrapQtApps = true;

    cmakeFlags = [
        # We're allowed to used the API ID of the Snap package:
        (lib.cmakeFeature "TDESKTOP_API_ID" "611335")
        (lib.cmakeFeature "TDESKTOP_API_HASH" "d524b414d21f4d37f08684c1df41ac9c")
        # swift 6 is not available in nixpkgs
        (lib.cmakeBool "DESKTOP_APP_DISABLE_SWIFT6" true)
    ];

    passthru = {
        inherit tg_owt;
        updateScript = nix-update-script {};
    };

    meta = {
        description = "Telegram Desktop messaging app";
        longDescription = ''
            Desktop client for the Telegram messenger, based on the Telegram API and
            the MTProto secure protocol.
        '';
        license = lib.licenses.gpl3Only;
        platforms = ["x86_64-linux"];
        homepage = "https://desktop.telegram.org/";
        changelog = "https://github.com/telegramdesktop/tdesktop/releases/tag/v${finalAttrs.version}";
        maintainers = with lib.maintainers; [nickcao];
        mainProgram = "Telegram";
    };
})
