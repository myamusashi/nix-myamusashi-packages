{
    lib,
    rustPlatform,
    fetchFromGitHub,
}:
rustPlatform.buildRustPackage (finalAttrs: {
    pname = "tlottie";
    version = "1.0.6";

    src = fetchFromGitHub {
        owner = "dkaraush";
        repo = "tlottie";
        tag = "v${finalAttrs.version}";
        hash = "sha256-WtYyyf7AL+jtYY368X26PTnKSBUSZ9+IZjod/T5Oceg=";
        fetchSubmodules = true;
    };

    cargoLock = {
        lockFile = finalAttrs.src + "/Cargo.lock";
    };

    # Same recipe upstream uses: C staticlib behind the `c-api` feature.
    # `cargo build` has no --crate-type, so build via `cargo rustc`;
    # cargoSetupHook already vendored deps + offline config, stays hermetic.
    dontCargoBuild = true;
    buildPhase = ''
        runHook preBuild
        cargo rustc --offline --lib --release --locked \
            --features c-api --crate-type staticlib \
            -- --print native-static-libs
        runHook postBuild
    '';

    # No tests run: default `cargo test` would also build the cli/helper targets.
    doCheck = false;

    # Custom install disables cargoInstallHook/PostBuildHook: we ship only the
    # C staticlib + header, exactly what cmake_helpers' external/tlottie looks
    # up via DESKTOP_APP_TLOTTIE_LIBRARY / DESKTOP_APP_TLOTTIE_INCLUDE_DIR.
    installPhase = ''
        runHook preInstall
        install -Dm644 target/release/libtlottie.a -t "$out/lib"
        install -Dm644 include/tlottie.h -t "$out/include/tlottie"
        runHook postInstall
    '';

    meta = {
        description = "Rust library for drawing Lottie animations (C staticlib for Telegram Desktop)";
        homepage = "https://github.com/dkaraush/tlottie";
        license = lib.licenses.mit;
        platforms = ["x86_64-linux"];
    };
})
