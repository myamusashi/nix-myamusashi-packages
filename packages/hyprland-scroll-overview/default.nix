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
    version = "unstable-44a4b651";

    src = fetchFromGitHub {
        owner = "myamusashi";
        repo = pname;
        rev = "44a4b6511cad7a55711b2b99c42fb06005d1a901";
        hash = "sha256-Y6NLiZnEXX83UVYMsU41+hq+q0xabvQbmi4LOXI+pZU=";
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
