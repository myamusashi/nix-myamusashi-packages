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
    version = "unstable-a9d098a8";

    src = fetchFromGitHub {
        owner = "desktop-app";
        repo = "tg_owt";
        rev = "a9d098a8f126dff818889d56f4241d7d2aaac9c1";
        hash = "sha256-SVVhnwZzv3yVh2GHwAog7Jgw59jCqekPHHsrCd2O/Nk=";
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
