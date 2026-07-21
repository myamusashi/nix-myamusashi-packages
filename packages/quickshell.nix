{
    lib,
    stdenv,
    fetchFromGitHub,
    pkg-config,
    cmake,
    ninja,
    spirv-tools,
    vulkan-headers,
    qt6,
    cpptrace,
    jemalloc,
    cli11,
    wayland,
    wayland-protocols,
    wayland-scanner,
    libxcb,
    libdrm,
    libgbm,
    pipewire,
    pam,
    glib,
    polkit,
}:
stdenv.mkDerivation (finalAttrs: {
    pname = "quickshell";
    version = "unstable-e649d247";

    src = fetchFromGitHub {
        owner = "quickshell-mirror";
        repo = "quickshell";
        rev = "e649d247498512464457aefcd05b73038c4e65a1";
        hash = "sha256-4i2GzlclQ+SEYlcEZs0kFNI8iBk+sbQlVUtMiiogvck=";
    };

    nativeBuildInputs = [
        cmake
        ninja
        qt6.qtshadertools
        spirv-tools
        vulkan-headers
        wayland-scanner
        qt6.wrapQtAppsHook
        pkg-config
    ];

    buildInputs = [
        qt6.qtbase
        qt6.qtdeclarative
        qt6.qtwayland
        qt6.qtsvg
        cli11
        wayland
        wayland-protocols
        libdrm
        libgbm
        cpptrace
        jemalloc
        libxcb
        pam
        pipewire
        glib
        polkit
    ];

    cmakeFlags = [
        (lib.cmakeFeature "DISTRIBUTOR" "Nixpkgs")
        (lib.cmakeFeature "INSTALL_QML_PREFIX" qt6.qtbase.qtQmlPrefix)
        (lib.cmakeFeature "GIT_REVISION" "tag-v${finalAttrs.version}")
    ];

    cmakeBuildType = "RelWithDebInfo";
    separateDebugInfo = true;
    dontStrip = false;

    meta = {
        homepage = "https://quickshell.org";
        description = "Flexbile QtQuick based desktop shell toolkit";
        license = lib.licenses.lgpl3Only;
        platforms = lib.platforms.linux;
        mainProgram = "quickshell";
        maintainers = with lib.maintainers; [outfoxxed];
    };
})
