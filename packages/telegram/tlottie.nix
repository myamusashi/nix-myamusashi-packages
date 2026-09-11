{
  lib,
  stdenv,
  fetchFromGitHub,
  rustc,
  cargo,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "tlottie";
  # Pinned to the rev tdesktop builds against, see in tdesktop:
  # - Telegram/build/docker/centos_env/Dockerfile (tlottie stage)
  # - Telegram/build/prepare/prepare.py (stage 'tlottie')
  # - snap/snapcraft.yaml (tlottie part)
  version = "0-unstable-2026-09-08";

  src = fetchFromGitHub {
    owner = "dkaraush";
    repo = "tlottie";
    rev = "4b940c7942fbde8ee56f10f39a5224a4153bd91e";
    hash = "sha256-Nddb4lGC3XvltwBbPHMUdM7F87en/H0T5allfjxWHO8=";
  };

  nativeBuildInputs = [
    rustc
    cargo
  ];

  # Same recipe upstream uses: C staticlib behind the `c-api` feature.
  # Installs $out/lib/libtlottie.a + $out/include/tlottie/tlottie.h, which is
  # exactly what cmake_helpers' external/tlottie looks up via
  # DESKTOP_APP_TLOTTIE_LIBRARY / DESKTOP_APP_TLOTTIE_INCLUDE_DIR.
  preBuild = ''
    export CARGO_HOME=$(mktemp -d)
  '';

  buildPhase = ''
    runHook preBuild
    cargo rustc --lib --release --locked \
        --features c-api --crate-type staticlib \
        -- --print native-static-libs
    runHook postBuild
  '';

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
    platforms = [ "x86_64-linux" ];
  };
})
