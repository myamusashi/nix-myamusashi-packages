{
    lib,
    stdenv,
    rustPlatform,
    rustc,
    fetchFromGitHub,
    pkg-config,
    patchelf,
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
    craft-fonts,
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
        version = "unstable-3f555bc8";

        __structuredAttrs = true;
        strictDeps = true;

        env = {
            CRAFT_FONTS_DIR = "${craft-fonts}";
            CRAFT_FONTS_REQUIRED = "1";
        };

        src = fetchFromGitHub {
            owner = "storytold";
            repo = "wordcraft";
            rev = "3f555bc85dc9cc742ddae9f287cfc7b93a87480b";
            hash = "sha256-ao83/wiB2QXzRn1XInaZVm4eXOaH2AaCupr7C6FilPI=";
        };

        doCheck = false;
        doInstallCheck = false;

        cargoHash = "sha256-FpzFuyTGUeiH62V3V9M0bvTcoRF/snHASOv2TPpzhlY=";

        postPatch = ''
            substituteInPlace Cargo.toml \
              --replace-fail $'egui_demo_lib = { git = "https://github.com/storytold/egui.git", rev = "6d518fc799681571963842f95b55a6b68431b15a" }\n' "" \
              --replace-fail $'egui_inspection = { git = "https://github.com/storytold/egui.git", rev = "6d518fc799681571963842f95b55a6b68431b15a" }\n' "" \
              --replace-fail $'egui_extras = { git = "https://github.com/storytold/egui.git", rev = "6d518fc799681571963842f95b55a6b68431b15a" }\n' "" \
              --replace-fail $'egui_system_font_provider = { git = "https://github.com/storytold/egui.git", rev = "6d518fc799681571963842f95b55a6b68431b15a" }\n' ""
        '';

        cargoBuildFlags = [
            "--package=wordcraft"
            "--package=wordcraft-cli"
        ];

        cargoTestFlags = [
            "--package=wordcraft-cli"
        ];

        __darwinAllowLocalNetworking = true;

        nativeBuildInputs = [
            pkg-config
            patchelf
        ];

        postInstall = lib.optionalString stdenv.hostPlatform.isLinux ''
            mkdir -p $out/share/icons
            cp -R assets/app-icon/hicolor $out/share/icons/
            install -Dm644 packaging/linux/ai.storyteller.wordcraft.desktop \
              $out/share/applications/ai.storyteller.wordcraft.desktop
            install -Dm644 packaging/linux/ai.storyteller.wordcraft.mime.xml \
              $out/share/mime/packages/ai.storyteller.wordcraft.xml
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
