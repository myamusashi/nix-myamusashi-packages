{
    lib,
    stdenv,
    runCommand,
    fetchFromGitHub,
    pdfjs,
    chromium-hsts-preload-list,
    cmake,
    gitMinimal,
    ninja,
    pkg-config,
    curlFull, # Websocket support
    libavif,
    angle, # libEGL
    brotli,
    cpptrace,
    glib,
    glslang,
    harfbuzz,
    libdrm,
    libGL,
    libjpeg_turbo,
    libpng,
    libpsl,
    libxml2,
    libedit,
    libpulseaudio,
    libwebp,
    mimalloc,
    openssl,
    perl,
    python3,
    qt6Packages,
    woff2,
    wuffs,
    cargo,
    fast-float,
    ffmpeg,
    fontconfig,
    rustPlatform,
    rustc,
    simdutf,
    skia,
    nixosTests,
    unstableGitUpdater,
    _experimental-update-script-combinators,
    common-updater-scripts,
    libtommath,
    sdl3,
    icu78,
    simdjson,
    sqlite,
    vulkan-headers,
    vulkan-loader,
    vulkan-memory-allocator,
    zlib,
    zmij,
}:
stdenv.mkDerivation (finalAttrs: {
    pname = "ladybird";
    version = "2026.47.7";

    src = fetchFromGitHub {
        owner = "LadybirdBrowser";
        repo = "ladybird";
        rev = "${finalAttrs.version}";
        hash = "sha256-ZSJ6QjGA7MAR/8joe0NwkhJyWZw/ag4tOCd0+F7siAA=";
    };

    cargoDeps = rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname version src;
        hash = "sha256-fYqoQxHodl7DJMfjp3S000CF8kFSD996LTH3dKg7Dtw=";
    };

    postPatch = ''
        sed -i '/iconutil/d' UI/CMakeLists.txt

        # https://github.com/LadybirdBrowser/ladybird/pull/12751
        # New Rust releases can deprecate APIs used by this snapshot.
        substituteInPlace Meta/CMake/rust_crate.cmake \
          --replace-fail 'set(RUSTC_TARGET_FLAGS -Dwarnings ' 'set(RUSTC_TARGET_FLAGS '

        # Upstream suffixes its reduced FFmpeg build to coexist with system FFmpeg.
        # Use nixpkgs' FFmpeg, which already provides the additional decoders.
        substituteInPlace Meta/CMake/check_for_dependencies.cmake \
          --replace-fail libavcodec-ladybird libavcodec \
          --replace-fail libavutil-ladybird libavutil \
          --replace-fail libswresample-ladybird libswresample

        perl -0pi -e \
          's/find_package\(ICU 78\.[0-9]+ EXACT REQUIRED COMPONENTS data i18n uc\)/find_package(ICU ${icu78.version} EXACT REQUIRED COMPONENTS data i18n uc)/ or die "ICU dependency not found\n"' \
          Meta/CMake/check_for_dependencies.cmake

        # Install the same PDF viewer assets and integration patch as the vcpkg build.
        cp -r ${pdfjs}/share/pdf.js pdfjs
        chmod -R u+w pdfjs
        patch -d pdfjs -p1 < Meta/CMake/vcpkg/overlay-ports/pdfjs/0001-ladybird-embed.patch

        # Don't set absolute paths in RPATH
        substituteInPlace Meta/CMake/lagom_install_options.cmake \
          --replace-fail "\''${CMAKE_INSTALL_BINDIR}" "bin" \
          --replace-fail "\''${CMAKE_INSTALL_LIBDIR}" "lib"
    '';

    preConfigure = ''
        # HSTS preload data is the only remaining downloaded data cache.
        mkdir -p build/Caches
        cmakeFlagsArray+=(
          "-DLADYBIRD_CACHE_DIR=$PWD/build/Caches"
          "-DPDFJS_DIR=$PWD/pdfjs"
        )

        mkdir build/Caches/HSTSPreload
        cp ${chromium-hsts-preload-list}/share/chromium-hsts-preload-list/transport_security_state_static.json build/Caches/HSTSPreload
    '';

    nativeBuildInputs =
        [
            cargo
            cmake
            gitMinimal
            ninja
            perl
            pkg-config
            python3
            rustPlatform.cargoSetupHook
            rustc
            qt6Packages.wrapQtAppsHook
        ]
        ++ lib.optionals stdenv.hostPlatform.isLinux [glslang];

    buildInputs =
        [
            curlFull
            brotli
            cpptrace
            fast-float
            ffmpeg
            fontconfig
            harfbuzz
            libavif
            angle # libEGL
            libGL
            libjpeg_turbo
            libpng
            libpsl
            libtommath
            libxml2
            libedit
            libwebp
            (runCommand "llvm-libc-headers" {
                    src = fetchFromGitHub {
                        owner = "llvm";
                        repo = "llvm-project";
                        rev = "e54169423e7ee5d8b41c2f1b6f7a59000c901ee0";
                        sparseCheckout = ["libc"];
                        hash = "sha256-rYvY2rTNwA3Ovy3y/hI3nTp9v8kJbhxB2gseLcZ5vWA=";
                    };
                } ''
                    for dir in hdr include shared src/__support src/string/memory_utils; do
                        (cd "$src/libc" && find "$dir" -type f -name '*.h' -exec install -Dm644 {} "$out/include/llvm-libc/{}" \;)
                    done
                '')
            (mimalloc.overrideAttrs {
                # Ladybird uses heap APIs removed in mimalloc 3.
                version = "2.2.7";
                src = fetchFromGitHub {
                    owner = "microsoft";
                    repo = "mimalloc";
                    tag = "v2.2.7";
                    hash = "sha256-z9qMOTcGkURblZChXDGfQ58hrql52lG6EE1NQmxxuj0=";
                };
            })
            openssl
            qt6Packages.qtbase
            qt6Packages.qtpositioning
            sdl3
            simdutf
            (skia.overrideAttrs (prev: {
                # Ladybird also uses Skia's color management API directly.
                gnFlags =
                    prev.gnFlags
                    ++ [
                        "extra_cflags+=[\"-DSKCMS_DLL\"]"
                    ];
            }))
            wuffs
            woff2
            icu78
            simdjson
            sqlite
            zlib
            zmij
        ]
        ++ lib.optionals stdenv.hostPlatform.isLinux [
            libpulseaudio.dev
            glib
            libdrm
            qt6Packages.qtwayland
            vulkan-headers
            vulkan-loader
            vulkan-memory-allocator
        ];

    cmakeFlags =
        [
            # Takes an enormous amount of resources, even with mold
            (lib.cmakeBool "ENABLE_LTO_FOR_RELEASE" false)
            # Disable network operations
            "-DENABLE_NETWORK_DOWNLOADS=OFF"
            # Ladybird requires icu 78, but without this flag the default icu
            # from other dependencies gets picked up instead.
            (lib.cmakeFeature "ICU_ROOT" (toString icu78.dev))
            # Upstream defaults to -Ctarget-cpu=native for Rust, which cc-wrapper
            # cannot strip; target a portable baseline instead.
            (lib.cmakeBool "ENABLE_CI_BASELINE_CPU" true)
        ]
        ++ lib.optionals stdenv.hostPlatform.isLinux [
            "-DCMAKE_INSTALL_LIBEXECDIR=libexec"
        ];

    # ld: [...]/OESVertexArrayObject.cpp.o: undefined reference to symbol 'glIsVertexArrayOES'
    # ld: [...]/libGL.so.1: error adding symbols: DSO missing from command line
    # https://github.com/LadybirdBrowser/ladybird/issues/371#issuecomment-2616415434
    env.NIX_LDFLAGS = lib.optionalString stdenv.hostPlatform.isLinux "-lGL " + "-lfontconfig";

    passthru.tests = {
        nixosTest = nixosTests.ladybird;
    };

    passthru.updateScript = let
        updateSource = unstableGitUpdater {
            hardcodeZeroVersion = true;
        };

        updateCargoDeps = {
            command = [
                (lib.getExe' common-updater-scripts "update-source-version")
                "ladybird"
                "--ignore-same-version"
                "--source-key=cargoDeps.vendorStaging"
            ];
        };
    in
        _experimental-update-script-combinators.sequence [
            updateSource
            updateCargoDeps
        ];

    meta = {
        description = "Browser using the SerenityOS LibWeb engine with a Qt or Cocoa GUI";
        homepage = "https://ladybird.org";
        license = lib.licenses.bsd2;
        maintainers = with lib.maintainers; [
            fgaz
            jk
            schembriaiden
        ];
        platforms = [
            "x86_64-linux"
            "aarch64-linux"
        ];
        mainProgram = "Ladybird";
    };
})
