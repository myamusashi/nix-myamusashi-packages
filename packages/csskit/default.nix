{
    lib,
    rustPlatform,
    pkg-config,
    openssl,
    fetchFromGitHub,
}:
rustPlatform.buildRustPackage {
    pname = "csskit";
    version = "unstable-232ca88c";

    src = fetchFromGitHub {
        owner = "csskit";
        repo = "csskit";
        rev = "232ca88c620f80801f6b46e6cda9d80c195a67c2";
        hash = "sha256-Rxx8EWPQIUbG7FOQl5m8/hTs4+Xx6B0b4MbCeLthX5o=";
    };

    cargoHash = "sha256-ZWQWAMW/0mZThGELDcaPdEjplY+4dcBPTJe2F2Mstvc=";

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
