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
    version = "unstable-05441765";

    src = fetchFromGitHub {
        owner = "myamusashi";
        repo = "hyprland-scroll-overview";
        rev = "0544176550dccb345a6ccf5567a3693407c2f903";
        hash = "sha256-IldjUm7fw8AqLQkh6pJVa5DH9jFdc40J9m94/+0ZhV8=";
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
