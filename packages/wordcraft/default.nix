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
    aws-lc,
    nix-update-script,
    craft-fonts,
    craft-i18n,
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
        version = "unstable-4700018b";

        __structuredAttrs = true;
        strictDeps = true;

        env = {
            CRAFT_FONTS_DIR = "${craft-fonts}";
            CRAFT_FONTS_REQUIRED = "1";
            CRAFT_I18N_DIR = "${craft-i18n}";
            CRAFT_I18N_REQUIRED = "1";
        };

        src = fetchFromGitHub {
            owner = "storytold";
            repo = "wordcraft";
            rev = "4700018be759ed3b2ce2fdf064aeaa168b688ffb";
            hash = "sha256-ne0PpW6uR6FOHtGSm33KtIFjWamTHol+TW5xVzLf18A=";
        };

        doCheck = false;
        doInstallCheck = false;

        cargoHash = "sha256-aEi8Jvz8pslCw7jEguPvTeMlwvBXiHCIiwc2oVfOjgc=";

        postPatch = ''
            while IFS= read -r crateName; do
                sed -i "/^''${crateName} = { git = /d" Cargo.toml
                if grep -q "^''${crateName} = { git = " Cargo.toml; then
                    echo "failed to remove ''${crateName} from Cargo.toml" >&2
                    exit 1
                fi
            done < <(awk '/^\[\[patch\.unused\]\]/{f=1; next} f && /^name = "/{gsub(/^name = "|"/, ""); print; f=0}' Cargo.lock)
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

        buildInputs = [
            aws-lc
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
