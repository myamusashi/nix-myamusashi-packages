{
    stdenvNoCC,
    hyprland,
    gcc14,
    fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
    pname = "hypr-dynamic-cursors";
    version = "unstable-b9739b1d";

    src = fetchFromGitHub {
        owner = "VirtCode";
        repo = pname;
        rev = "b9739b1db4a48616d66af29239ab0fe2756d28f6";
        hash = "sha256-v+7e4T412K3Hi/qb+v7sZh2/2k1jFB9AY4AusVXr58I=";
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
