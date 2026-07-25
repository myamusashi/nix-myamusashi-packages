{
    lib,
    rustPlatform,
    pkg-config,
    openssl,
    fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
    pname = "csskit";
    version = "unstable-81c9273e";

    src = fetchFromGitHub {
        owner = "csskit";
        repo = "csskit";
        rev = "81c9273e472333947f90035d2bb6391c913db0cd";
        hash = "sha256-im+KBaNp2OquQT0ySFBx/csg7qj+sWFu7EnTzBo1c30=";
    };

    cargoHash = "sha256-mWpZPNahVmGsgjBnX4Qhde2/3Mbslx8k7QmHmA1XcFs=";

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
