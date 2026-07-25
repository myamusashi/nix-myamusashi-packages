{
    stdenv,
    hyprland,
    gcc14,
    pkg-config,
    lua5_4,
    fetchFromGitHub,
}:
stdenv.mkDerivation {
    pname = "hyprland-scroll-overview";
    version = "unstable-9b00202f";

    src = fetchFromGitHub {
        owner = "myamusashi";
        repo = "hyprland-scroll-overview";
        rev = "9b00202fddb271a71286e5c13bc881ecdff7113c";
        hash = "sha256-J95a94cOdr+zehnJybS2jgwyne7fjAx1WihZJo6tXC4=";
    };

    inherit (hyprland) buildInputs;
    nativeBuildInputs =
        hyprland.nativeBuildInputs
        ++ [
            hyprland
            gcc14
            pkg-config
            lua5_4
        ];

    enableParallelBuilding = true;

    buildPhase = ''
        runHook preBuild
        make all
        runHook postBuild
    '';

    installPhase = ''
        runHook preInstall
        mkdir -p "$out/lib"
        cp libscrolloverview.so "$out/lib/libscrolloverview.so"
        runHook postInstall
    '';
}
