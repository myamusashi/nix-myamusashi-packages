{
    lib,
    stdenv,
    callPackage,
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
    dbus,
    glib,
    glslang,
    harfbuzz,
    libdrm,
    libGL,
    libjpeg_turbo,
    libpng,
    libpsl,
    libedit,
    libpulseaudio,
    libwebp,
    libxml2,
    mimalloc,
    openssl,
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
    nix-update-script,
    sdl3,
    icu78,
    simdjson,
    sqlite,
    vulkan-headers,
    vulkan-loader,
    vulkan-memory-allocator,
    zlib,
    zmij,
}: let
    llvmLibcHeaders = callPackage ./llvm-libc-headers.nix {};
in
    stdenv.mkDerivation (finalAttrs: {
        pname = "ladybird";
        version = "2026.47.7";

        src = fetchFromGitHub {
            owner = "LadybirdBrowser";
            repo = "ladybird";
            tag = finalAttrs.version;
            hash = "sha256-LWzmolLf0JDXASaFQ79jE75Oy6r7eaAeysOEKzUCZzA=";
            nativeBuildInputs = [gitMinimal];
            # Keep the commit shown in About Ladybird when building from an archive.
            postFetch = ''
                gzip -dc "$renamed" | {
                  git get-tar-commit-id > "$out/REVISION" || exit 1
                  cat > /dev/null
                }
            '';
        };

        cargoDeps = rustPlatform.fetchCargoVendor {
            inherit (finalAttrs) pname version src;
            hash = "sha256-fYqoQxHodl7DJMfjp3S000CF8kFSD996LTH3dKg7Dtw=";
        };

        patches = lib.optionals stdenv.hostPlatform.isLinux [
            ./patches/ffmpeg-optional-av1-workaround.patch
            ./patches/linux-native-egl.patch
        ];

        postPatch =
            ''
                sed -i '/iconutil/d' UI/CMakeLists.txt

                # https://github.com/LadybirdBrowser/ladybird/pull/12751
                # New Rust releases can deprecate APIs used by this snapshot.
                substituteInPlace Meta/CMake/rust_crate.cmake \
                  --replace-fail 'set(RUSTC_TARGET_FLAGS -Dwarnings ' 'set(RUSTC_TARGET_FLAGS '

                # Use nixpkgs' FFmpeg without the suffix used by Ladybird's bundled copy.
                substituteInPlace Meta/CMake/check_for_dependencies.cmake \
                  --replace-fail libavcodec-ladybird libavcodec \
                  --replace-fail libavutil-ladybird libavutil \
                  --replace-fail libswresample-ladybird libswresample

                # Install the same PDF viewer assets and integration patch as the vcpkg build.
                cp -r ${pdfjs}/share/pdf.js pdfjs
                chmod -R u+w pdfjs
                patch -d pdfjs -p1 < Meta/CMake/vcpkg/overlay-ports/pdfjs/0001-ladybird-embed.patch

                # Don't set absolute paths in RPATH
                substituteInPlace Meta/CMake/lagom_install_options.cmake \
                  --replace-fail "\''${CMAKE_INSTALL_BINDIR}" "bin" \
                  --replace-fail "\''${CMAKE_INSTALL_LIBDIR}" "lib"
            ''
            + lib.optionalString stdenv.hostPlatform.isLinux ''
                substituteInPlace Services/Compositor/main.cpp \
                  --replace-fail '@NIX_NATIVE_EGL@' '${lib.getLib libGL}/lib/libEGL.so.1'
                substituteInPlace Libraries/LibSandbox/GpuDriverPaths.cpp \
                  --replace-fail '@NIX_DRIVER_LINK@' '${libGL.driverLink}' \
                  --replace-fail '@NIX_STORE_DIR@' '${builtins.storeDir}'
            '';

        preConfigure = ''
            # Use upstream's PDF.js discovery with our patched distribution.
            cmakeFlagsArray+=("-DPDFJS_DIR=$PWD/pdfjs")

            # HSTS preload data is the only remaining downloaded data cache.
            mkdir -p build/Caches
            cmakeFlagsArray+=("-DLADYBIRD_CACHE_DIR=$PWD/build/Caches")

            mkdir build/Caches/HSTSPreload
            cp ${chromium-hsts-preload-list}/share/chromium-hsts-preload-list/transport_security_state_static.json build/Caches/HSTSPreload
        '';

        nativeBuildInputs =
            [
                cargo
                cmake
                gitMinimal
                ninja
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
                libedit
                libwebp
                libxml2
                llvmLibcHeaders
                (mimalloc.overrideAttrs (prev: {
                    # Ladybird uses heap APIs removed in mimalloc 3.
                    version = "2.2.7";
                    src = fetchFromGitHub {
                        owner = "microsoft";
                        repo = "mimalloc";
                        tag = "v2.2.7";
                        hash = "sha256-z9qMOTcGkURblZChXDGfQ58hrql52lG6EE1NQmxxuj0=";
                    };
                    # Upstream disables block padding to avoid inflating allocation size classes.
                    cmakeFlags = prev.cmakeFlags ++ [(lib.cmakeBool "MI_NO_PADDING" true)];
                }))
                openssl
                qt6Packages.qtbase
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
                dbus
                libpulseaudio
                glib
                libdrm
                qt6Packages.qtpositioning
                qt6Packages.qtsvg
                qt6Packages.qtwayland
                vulkan-headers
                vulkan-loader
                vulkan-memory-allocator
            ];

        cmakeFlags =
            [
                # Disable network operations
                "-DENABLE_NETWORK_DOWNLOADS=OFF"
                # Nix manages updates. This also disables Sparkle on macOS.
                (lib.cmakeBool "LADYBIRD_ENABLE_UPDATE_CHECK" false)
                (lib.cmakeFeature "LADYBIRD_VERSION" finalAttrs.version)
                # Ladybird requires icu 78, but without this flag the default icu
                # from other dependencies gets picked up instead.
                (lib.cmakeFeature "ICU_ROOT" (toString icu78.dev))
                # Upstream defaults to -Ctarget-cpu=native for Rust, which cc-wrapper
                # cannot strip; target a portable baseline instead.
                (lib.cmakeBool "LADYBIRD_BASELINE_CPU_TARGET" true)
            ]
            ++ lib.optionals stdenv.hostPlatform.isLinux [
                "-DCMAKE_INSTALL_LIBEXECDIR=libexec"
            ];

        passthru.tests = {
            nixosTest = nixosTests.ladybird;
        };

        passthru.updateScript = nix-update-script {};

        meta = {
            description = "Browser using the SerenityOS LibWeb engine with a Qt GUI";
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
