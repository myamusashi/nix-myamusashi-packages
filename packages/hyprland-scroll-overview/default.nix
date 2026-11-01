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
    version = "unstable-dcdd3b50";

    src = fetchFromGitHub {
        owner = "yayuuu";
        repo = pname;
        rev = "dcdd3b502617e70fb3a9fd3b568d20440048008a";
        hash = "sha256-bhZvO6hJINAWDxqS2XzmR1h5NUHkxzuNXr5IzgTG4+w=";
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
