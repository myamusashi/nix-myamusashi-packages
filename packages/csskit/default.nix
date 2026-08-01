{
    lib,
    rustPlatform,
    pkg-config,
    openssl,
    fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
    pname = "csskit";
    version = "unstable-c4ada357";

    src = fetchFromGitHub {
        owner = "csskit";
        repo = "csskit";
        rev = "c4ada3570cd869611e24440f661bac5105d0e59d";
        hash = "sha256-l52cAQcptrFwF4kexDi0LzMC0LUmKwQB+Cw0QcxInnU=";
    };

    cargoHash = "sha256-1PNvptZOKG+JjFEIS2MZJGKhLVgzuTzuxGbdqpPcz68=";

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
