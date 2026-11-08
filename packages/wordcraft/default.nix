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
        version = "unstable-fde39ab0";

        __structuredAttrs = true;
        strictDeps = true;

        env = {
            CRAFT_FONTS_DIR = "${craft-fonts}";
            CRAFT_FONTS_REQUIRED = "1";
        };

        src = fetchFromGitHub {
            owner = "storytold";
            repo = "wordcraft";
            rev = "fde39ab0615d9153db933d11752b8d0fc4505e30";
            hash = "sha256-NwRZihCFcQKPcAOWPYo5x4SP9aXIhsvVGX0F7xDOoYQ=";
        };

        doCheck = false;
        doInstallCheck = false;

        cargoHash = "sha256-UOzegHh5SSoItkyLto7y+yOgCRB+swGk43pjYtY0Rvk=";

        postPatch = let
            unusedPatchedCrates = [
                "egui_demo_lib"
                "egui_inspection"
                "egui_system_font_provider"
            ];
        in
            lib.concatMapStrings (crateName: ''
                sed -i '/^${crateName} = { git = /d' Cargo.toml
                if grep -q '^${crateName} = { git = ' Cargo.toml; then
                    echo "failed to remove ${crateName} from Cargo.toml" >&2
                    exit 1
                fi
            '')
            unusedPatchedCrates;

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
