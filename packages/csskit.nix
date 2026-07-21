{
    lib,
    rustPlatform,
    pkg-config,
    openssl,
    fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
    pname = "csskit";
    version = "unstable-50b0b490";

    src = fetchFromGitHub {
        owner = "csskit";
        repo = "csskit";
        rev = "50b0b490d0bf0109209803df4daca097e803cba4";
        hash = "sha256-TKOlolookrLouOxxg6YNDA0EpcaD7nEzP/sc5xm98Zo=";
    };

    cargoHash = "sha256-4hryB5nzNE5QC2bkWkK9t4x3VGt0fT4LFmP2kB2cdCM=";

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
