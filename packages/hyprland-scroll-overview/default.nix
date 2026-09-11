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
    version = "unstable-5e96ae20";

    src = fetchFromGitHub {
        owner = "yayuuu";
        repo = pname;
        rev = "5e96ae20ec73c320248bcf3ff68b330bc1ed4152";
        hash = "sha256-clDeTM5itsJPvqpbEkbWUmuPROsz2+YUnTpqsjQDMqU=";
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
