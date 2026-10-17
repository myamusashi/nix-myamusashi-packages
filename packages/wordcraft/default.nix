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
        version = "unstable-eae24217";

        __structuredAttrs = true;
        strictDeps = true;

        src = fetchFromGitHub {
            owner = "storytold";
            repo = "wordcraft";
            rev = "eae242176108d328c5dd81fbc10370c51ab90706";
            hash = "sha256-URerLuATjpPV8mQRrMLtWTNFXtbIasS0eP7dL2yD0cU=";
        };

        doCheck = false;
        doInstallCheck = false;

        cargoHash = "sha256-7kBw2GqhUAsxDR6185PDxeyfosSl9Fox1xxaElmpgjQ=";

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
