{
    lib,
    rustPlatform,
    fetchFromGitHub,
}:
rustPlatform.buildRustPackage (finalAttrs: {
    pname = "tlottie";
    version = "0-unstable-2026-08-03";

    src = fetchFromGitHub {
        owner = "dkaraush";
        repo = "tlottie";
        rev = "19d51d3c19632a63fdbe17c62f10332d978cb940";
        hash = "sha256-Cb1XWnryZEKTyvhBeOsYX5KZG88zUOAlSRhfyIh06g4=";
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
