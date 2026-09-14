{
    lib,
    rustPlatform,
    fetchFromGitHub,
    pkg-config,
    cmake,
    makeWrapper,
    wrapGAppsHook4,
    autoPatchelfHook,
    glib,
    gtk4,
    webkitgtk_6_0,
    cairo,
    pango,
    gdk-pixbuf,
    graphene,
    libsoup_3,
    fontconfig,
    libxkbcommon,
    wayland,
    vulkan-loader,
    alsa-lib,
    gst_all_1,
    xorg,
    bubblewrap,
    xdg-dbus-proxy,
}:
rustPlatform.buildRustPackage rec {
    pname = "serein";
    version = "1.0.0-nightly.10.1";

    src = fetchFromGitHub {
        owner = "ViceVerse-cz";
        repo = "Serein";
        tag = "v${version}";
        hash = "sha256-d2Hf9bC1MvfyAgO1BW5bInqih+ez/yBdouJRFpuC6Rs=";
    };

    cargoLock = {
        lockFile = "${src}/Cargo.lock";
        outputHashes = {
            "ecolor-0.36.2" = "sha256-G9x6P6ksfbEx9sTqpgzvbuMxjDUTgW2ghImLB6nUx94=";
        };
    };

    cargoBuildFlags = [
        "--package"
        "serein"
    ];

    nativeBuildInputs = [
        pkg-config
        cmake
        makeWrapper
        wrapGAppsHook4
        autoPatchelfHook
    ];

    buildInputs = [
        glib
        gtk4
        webkitgtk_6_0
        cairo
        pango
        gdk-pixbuf
        graphene
        libsoup_3
        wayland
        libxkbcommon
        xorg.libX11
        xorg.libXi
        xorg.libXrandr
        xorg.libXcursor
        fontconfig
        vulkan-loader
        alsa-lib
        gst_all_1.gstreamer
        gst_all_1.gst-plugins-base
    ];

    runtimeDependencies = [
        vulkan-loader
    ];

    doCheck = false;

    preFixup = ''
        gappsWrapperArgs+=(
          --prefix PATH : "${
            lib.makeBinPath [
                bubblewrap
                xdg-dbus-proxy
            ]
        }"
          --prefix GST_PLUGIN_SYSTEM_PATH : "${
            lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" [
                gst_all_1.gst-plugins-base
                gst_all_1.gst-plugins-good
                gst_all_1.gst-libav
            ]
        }"
        )
    '';

    # Desktop integration from the repo's own packaging/linux tree.
    postInstall = ''
        install -Dm444 ${src}/packaging/linux/serein.desktop \
          $out/share/applications/org.serein.desktop.desktop
        substituteInPlace $out/share/applications/org.serein.desktop.desktop \
          --replace-fail "Exec=serein" "Exec=$out/bin/serein"
        for theme_dir in ${src}/packaging/linux/hicolor/*; do
          size=$(basename "$theme_dir")
          for icon in "$theme_dir"/apps/*; do
            if [ -f "$icon" ]; then
              install -Dm444 "$icon" "$out/share/icons/hicolor/$size/apps/$(basename "$icon")"
            fi
          done
        done
    '';

    meta = with lib; {
        description = "Tiny, performant, native Discord client written in Rust (egui/wgpu)";
        homepage = "https://github.com/ViceVerse-cz/Serein";
        license = with licenses; [
            mit
            asl20
        ];
        platforms = platforms.linux;
        mainProgram = "serein";
    };
}
