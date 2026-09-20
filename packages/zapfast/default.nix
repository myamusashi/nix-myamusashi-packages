{
    lib,
    rustPlatform,
    fetchFromGitHub,
    pkg-config,
    cmake,
    perl,
    makeWrapper,
    coreutils,
    dejavu_fonts,
    liberation_ttf,
    noto-fonts,
    alsa-lib,
    libglvnd,
    libxkbcommon,
    wayland,
    libX11,
    libxcb,
    libXcursor,
    libXi,
    libXrandr,
}:
rustPlatform.buildRustPackage (finalAttrs: {
    pname = "zapfast";
    version = "0.14.0";

    src = fetchFromGitHub {
        owner = "crmne";
        repo = "zapfast";
        tag = "v${finalAttrs.version}";
        hash = "sha256-8yGUUqedr5JnCIdLMhrT0o6hhBL0J1TNUBa/dUIoNB0=";
    };

    cargoLock = {
        lockFile = "${finalAttrs.src}/Cargo.lock";
        outputHashes = {
            "wacore-0.7.0" = "sha256-BivXjeyjeRkZqMVpNF/pF2JY1dfA4m7+a/gOa2QPlEE=";
        };
    };

    cargoBuildFlags = [
        "--package"
        "zapfast"
    ];

    nativeBuildInputs = [
        pkg-config
        cmake
        perl
        makeWrapper
        coreutils
    ];

    postPatch = ''
        substituteInPlace src/updates/install.rs \
          --replace-fail '/bin/sleep' 'sleep'
    '';

    preCheck = ''
        substituteInPlace src/bidi.rs \
          --replace-fail \
            '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf' \
            '${dejavu_fonts}/share/fonts/truetype/dejavu/DejaVuSans.ttf' \
          --replace-fail \
            '/usr/share/fonts/TTF/DejaVuSans.ttf' \
            '${dejavu_fonts}/share/fonts/truetype/dejavu/DejaVuSans.ttf' \
          --replace-fail \
            '/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf' \
            '${liberation_ttf}/share/fonts/truetype/LiberationSans-Regular.ttf' \
          --replace-fail \
            '/usr/share/fonts/liberation/LiberationSans-Regular.ttf' \
            '${liberation_ttf}/share/fonts/truetype/LiberationSans-Regular.ttf' \
          --replace-fail \
            '/usr/share/fonts/truetype/noto/NotoSansHebrew-Regular.ttf' \
            '${noto-fonts}/share/fonts/noto/NotoSansHebrew-Regular.ttf' \
          --replace-fail \
            '/usr/share/fonts/truetype/noto/NotoSansArabic-Regular.ttf' \
            '${noto-fonts}/share/fonts/noto/NotoSansArabic-Regular.ttf' \
    '';

    buildInputs = [
        alsa-lib
        libglvnd
        libxkbcommon
        wayland
        libX11
        libxcb
        libXcursor
        libXi
        libXrandr
    ];

    postInstall = ''
        install -Dm644 LICENSE -t $out/share/licenses/zapfast
        install -Dm644 README.md -t $out/share/doc/zapfast
        install -Dm644 packaging/applications/zapfast.desktop \
          -t $out/share/applications
        install -Dm644 packaging/icons/zapfast.svg \
          -t $out/share/icons/hicolor/scalable/apps
    '';

    postFixup = ''
        patchelf --add-rpath ${
            lib.makeLibraryPath [
                libglvnd
                libxkbcommon
                wayland
                libX11
                libxcb
                libXcursor
                libXi
                libXrandr
            ]
        } $out/bin/zapfast
    '';

    meta = with lib; {
        description = "Fast native WhatsApp client built with Rust and egui";
        homepage = "https://zapfast.rocks";
        license = licenses.mit;
        mainProgram = "zapfast";
        platforms = platforms.linux;
    };
})
