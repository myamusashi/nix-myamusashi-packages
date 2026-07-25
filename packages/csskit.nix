{
    lib,
    rustPlatform,
    pkg-config,
    openssl,
    fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
    pname = "csskit";
    version = "unstable-ad35ca44";

    src = fetchFromGitHub {
        owner = "csskit";
        repo = "csskit";
        rev = "ad35ca4462d138352e5f9305a28e771db90537b1";
        hash = "sha256-ma3LmrNFDhx0LQyXjvujd+IC56OV6gSkY2LU+EPIxsQ=";
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
