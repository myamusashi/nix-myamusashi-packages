{
    lib,
    rustPlatform,
    pkg-config,
    openssl,
    fetchFromGitHub,
}:
rustPlatform.buildRustPackage {
    pname = "csskit";
    version = "unstable-e7fea9bc";

    src = fetchFromGitHub {
        owner = "csskit";
        repo = "csskit";
        rev = "e7fea9bc81bc3e64e17a3f22539e8ae03b7f6965";
        hash = "sha256-B6sgN/R2R8MdV9tKTLzrmfdZwtwHJKGggw4uxpRMUh4=";
    };

    cargoHash = "sha256-m91vdFjsZeTYuuIRJ9WRBJxFY5991U9lzXBCAAxPUMM=";

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
