{
    lib,
    rustPlatform,
    pkg-config,
    openssl,
    fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
    pname = "csskit";
    version = "0.0.27";

    src = fetchFromGitHub {
        owner = "csskit";
        repo = "csskit";
        rev = "v${version}";
        hash = "sha256-6zSZX0vu8P5yyVCpHPiTVQei9RmLQBaS8cM14x4CA7I=";
    };

    cargoHash = "sha256-q7OG27AM8PxwzVEpbb+PrXv4XqzeJLcvpQX5dPIHFvc=";

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
