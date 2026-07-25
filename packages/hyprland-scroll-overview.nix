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
    version = "unstable-fdbf1923";

    src = fetchFromGitHub {
        owner = "myamusashi";
        repo = pname;
        rev = "fdbf19236b9607287122fbde15a04e39137d15ff";
        hash = "sha256-KzrYGBO64U8up5yZzuID82VZ1CLQ+4pM3A121aTd5aI=";
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
