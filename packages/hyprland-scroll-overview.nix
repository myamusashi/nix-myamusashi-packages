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
    version = "unstable-181e27c5";

    src = fetchFromGitHub {
        owner = "myamusashi";
        repo = "hyprland-scroll-overview";
        rev = "181e27c5953325b56029a89bb00387d887953688";
        hash = "sha256-IXnq9e19seqj4NwCcIybtgzJflT8qZ6zBUuXnuv5d1c=";
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
