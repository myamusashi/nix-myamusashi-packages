{
    stdenv,
    hyprland,
    gcc14,
    pkg-config,
    lua5_4,
    fetchFromGitHub,
}:
stdenv.mkDerivation rec {
    pname = "hyprland-scroll-overview";
    version = "unstable-3c1d2292";

    src = fetchFromGitHub {
        owner = "myamusashi";
        repo = pname;
        rev = "f58817e89b9d82de0b3f889c586f9b6154099d3d";
        hash = "sha256-57TiTdZAgyLvTwP4mKQ5XaguM7TyR6E8H0nnf9uzrTM=";
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
