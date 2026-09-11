{
    lib,
    rustPlatform,
    pkg-config,
    openssl,
    fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
    pname = "csskit";
    version = "unstable-a2ac1658";

    src = fetchFromGitHub {
        owner = "csskit";
        repo = "csskit";
        rev = "a2ac16581d472324cce9556ebe94bdf599efbf6a";
        hash = "sha256-prwL3s/GehA/aAoDQgi47Zr1jWmk/cBQGqj9TO0rT+Q=";
    };

    cargoHash = "sha256-0r0ujdiN8B8Q1VpqKiPnJAgvhQCWhDg55nYl2aiY5fs=";

    nativeBuildInputs = [pkg-config];
    buildInputs = [openssl];

    cargoBuildFlags = ["--package" "csskit"];
    cargoTestFlags = ["--package" "csskit"];

    meta = with lib; {
        description = "Refreshing CSS!";
        homepage = "https://csskit.rs";
        license = licenses.mit;
        mainProgram = "csskit";
        maintainers = [];
    };
}
