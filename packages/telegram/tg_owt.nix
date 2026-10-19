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
    version = "unstable-07fb35bc";

    src = fetchFromGitHub {
        owner = "desktop-app";
        repo = "tg_owt";
        rev = "07fb35bc33b3e79125a1beab7690e830f183f5d8";
        hash = "sha256-yQYIfDvwuX5vEnutqZlR7sBZvTkjC6/D9btE+X86+B4=";
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
