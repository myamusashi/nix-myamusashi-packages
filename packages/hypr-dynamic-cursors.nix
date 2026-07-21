{
    stdenvNoCC,
    hyprland,
    gcc14,
    fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
    pname = "hypr-dynamic-cursors";
    version = "unstable-29d10069";

    src = fetchFromGitHub {
        owner = "myamusashi";
        repo = "hypr-dynamic-cursors";
        rev = "29d10069fb288dd6c63971b772542be18f6a38de";
        hash = "sha256-CihuLSp7WNZWrus6dva/0wqmpdVNaTjp3WsYmSzDfkU=";
    };

    inherit (hyprland) buildInputs;
    nativeBuildInputs = hyprland.nativeBuildInputs ++ [hyprland gcc14];
    enableParallelBuilding = true;

    dontUseCmakeConfigure = true;
    dontUseMesonConfigure = true;
    dontUseNinjaBuild = true;
    dontUseNinjaInstall = true;

    installPhase = ''
        runHook preInstall

        mkdir -p "$out/lib"
        cp -r out/dynamic-cursors.so "$out/lib/lib${pname}.so"

        runHook postInstall
    '';
}
