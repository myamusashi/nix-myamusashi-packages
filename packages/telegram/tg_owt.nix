{
    lib,
    stdenv,
    fetchFromGitHub,
    pkg-config,
    cmake,
    ninja,
    python3,
    libjpeg,
    openssl,
    libopus,
    ffmpeg,
    openh264,
    crc32c,
    libvpx,
    libx11,
    libxtst,
    libxcomposite,
    libxdamage,
    libxext,
    libxrender,
    libxrandr,
    libxi,
    glib,
    abseil-cpp,
    pipewire,
    libgbm,
    libdrm,
    libGL,
    unstableGitUpdater,
}:
stdenv.mkDerivation {
    pname = "tg_owt";
    version = "unstable-ec71c06a";

    src = fetchFromGitHub {
        owner = "desktop-app";
        repo = "tg_owt";
        rev = "ec71c06aaaed1cfda8669d51cf3b8d5b447b2031";
        hash = "sha256-xMyIgNppl7LAMGggwdJ/vV4iz3fI/RP6rO58ZXHpcjQ=";
        fetchSubmodules = true;
    };

    patches = [
    ];

    postPatch = ''
        substituteInPlace src/modules/desktop_capture/linux/wayland/egl_dmabuf.cc \
          --replace-fail '"libEGL.so.1"' '"${lib.getLib libGL}/lib/libEGL.so.1"' \
          --replace-fail '"libGL.so.1"' '"${lib.getLib libGL}/lib/libGL.so.1"' \
          --replace-fail '"libgbm.so.1"' '"${lib.getLib libgbm}/lib/libgbm.so.1"' \
          --replace-fail '"libdrm.so.2"' '"${lib.getLib libdrm}/lib/libdrm.so.2"'
    '';

    outputs = [
        "out"
        "dev"
    ];

    nativeBuildInputs = [
        pkg-config
        cmake
        ninja
        python3
    ];

    propagatedBuildInputs = [
        libjpeg
        openssl
        libopus
        ffmpeg
        openh264
        crc32c
        libvpx
        abseil-cpp
        libx11
        libxtst
        libxcomposite
        libxdamage
        libxext
        libxrender
        libxrandr
        libxi
        glib
        pipewire
        libgbm
        libdrm
        libGL
    ];

    passthru.updateScript = unstableGitUpdater {};

    meta = {
        description = "Fork of Google's webrtc library for telegram-desktop";
        homepage = "https://github.com/desktop-app/tg_owt";
        license = lib.licenses.bsd3;
        maintainers = with lib.maintainers; [oxalica];
        platforms = lib.platforms.linux;
    };
}
