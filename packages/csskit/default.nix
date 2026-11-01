{
    lib,
    rustPlatform,
    pkg-config,
    openssl,
    fetchFromGitHub,
}:
rustPlatform.buildRustPackage {
    pname = "csskit";
    version = "unstable-d39e5308";

    src = fetchFromGitHub {
        owner = "csskit";
        repo = "csskit";
        rev = "d39e53080b75006c53f725cab7cda07260ddf485";
        hash = "sha256-wRldPU0jwoa6MA/6Z0VZS7HpyPvren0lATt34ZiOBaw=";
    };

    cargoHash = "sha256-m9vz71yIUZyTqHGqg5PasOFd84Ak0AZL6nBDcamxejk=";

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
