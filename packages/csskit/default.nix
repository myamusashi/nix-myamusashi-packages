{
    lib,
    rustPlatform,
    pkg-config,
    openssl,
    fetchFromGitHub,
}:
rustPlatform.buildRustPackage {
    pname = "csskit";
    version = "unstable-62cde388";

    src = fetchFromGitHub {
        owner = "csskit";
        repo = "csskit";
        rev = "62cde3888a3b4eae0cde81b6dbf3430505aa7e99";
        hash = "sha256-s8EEKGYkeUJ428pgi8t+Nv6VCG7tBiSZZLa0jH7brsk=";
    };

    cargoHash = "sha256-IlC7Q9EP/Zryba7fO/tT3JwHaFAmn2XdS0uzCAGTCD4=";

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
