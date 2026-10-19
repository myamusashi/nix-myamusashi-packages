{
    lib,
    rustPlatform,
    pkg-config,
    openssl,
    fetchFromGitHub,
}:
rustPlatform.buildRustPackage {
    pname = "csskit";
    version = "unstable-4f69c6e2";

    src = fetchFromGitHub {
        owner = "csskit";
        repo = "csskit";
        rev = "4f69c6e2aafcbfdce8bba5d44c0c04fe357f573e";
        hash = "sha256-C2Svlf2kEXXNT+HcMOxg5qBrA7kqsJ5KCkbR/D9qgpc=";
    };

    cargoHash = "sha256-653TpBYgLdilTE+bVKbDDp5BLg81dPRFhquTf2efZVE=";

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
