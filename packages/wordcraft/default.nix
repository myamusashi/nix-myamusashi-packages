{
    lib,
    stdenv,
    rustPlatform,
    rustc,
    fetchFromGitHub,
    pkg-config,
    patchelf,
    copyDesktopItems,
    makeDesktopItem,
    versionCheckHook,
    vulkan-loader,
    libxkbcommon,
    libx11,
    libxcb,
    libxcursor,
    libxi,
    libxrandr,
    wayland,
    dbus,
    nix-update-script,
}: let
    runtimeDeps = [
        libxkbcommon
        libx11
        libxcb
        libxcursor
        libxi
        libxrandr
        wayland
        vulkan-loader
        dbus
    ];
in
    rustPlatform.buildRustPackage (finalAttrs: {
        pname = "wordcraft";
        version = "unstable-d588e0b8";

        __structuredAttrs = true;
        strictDeps = true;

        src = fetchFromGitHub {
            owner = "storytold";
            repo = "wordcraft";
            rev = "d588e0b87329975d0b06a9cf91e4d7d2ebacb0f8";
            hash = "sha256-76BDLKg+2KaQ+DkiGAisMAfVk3EG7g2t0gMUmSfnPso=";
        };

        doCheck = false;
        doInstallCheck = false;

        cargoHash = "sha256-eHrYMklNn1j7qVgtN2dXyaR+ImhtxSRUvUrEZ2AyygQ=";

        cargoBuildFlags = [
            "--package=wordcraft"
            "--package=wordcraft-cli"
        ];

        __darwinAllowLocalNetworking = true;

        nativeBuildInputs = [
            pkg-config
            patchelf
            copyDesktopItems
        ];

        desktopItems = [
            (makeDesktopItem {
                name = "ai.storyteller.wordcraft";
                desktopName = "WordCraft";
                genericName = "Word Processor";
                comment = "Write and design documents; open and save Word files";
                exec = "wordcraft %F";
                tryExec = "wordcraft";
                icon = "ai.storyteller.wordcraft";
                terminal = false;
                startupNotify = true;
                startupWMClass = "ai.storyteller.wordcraft";
                categories = [
                    "Office"
                    "WordProcessor"
                ];
                keywords = [
                    "word"
                    "processor"
                    "document"
                    "docx"
                    "writer"
                    "text"
                    "letter"
                    "report"
                ];
                mimeTypes = [
                    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
                    "application/vnd.oasis.opendocument.text"
                    "application/rtf"
                    "text/markdown"
                    "text/x-tex"
                    "text/html"
                    "text/plain"
                ];
            })
        ];

        postInstall = lib.optionalString stdenv.hostPlatform.isLinux ''
            mkdir -p $out/share/icons
            cp -R assets/app-icon/hicolor $out/share/icons/
        '';

        postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
            patchelf --add-rpath ${lib.makeLibraryPath runtimeDeps} $out/bin/wordcraft
        '';

        nativeInstallCheckInputs = [versionCheckHook];

        passthru.updateScript = nix-update-script {};

        meta = {
            description = "Word processor with DOCX, ODT and RTF support";
            homepage = "https://github.com/storytold/wordcraft";
            changelog = "https://github.com/storytold/wordcraft/releases/tag/${finalAttrs.src.tag}";
            license = with lib.licenses;
                AND [
                    (OR [
                        mit
                        asl20
                    ])
                    ofl
                    cc0
                    publicDomain
                ];
            maintainers = with lib.maintainers; [sophronesis];
            mainProgram = "wordcraft";
            platforms = rustc.meta.platforms;
        };
    })
