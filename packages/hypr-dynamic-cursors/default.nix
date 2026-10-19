{
    stdenvNoCC,
    hyprland,
    gcc14,
    fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
    pname = "hypr-dynamic-cursors";
    version = "unstable-2a8d0b73";

    src = fetchFromGitHub {
        owner = "VirtCode";
        repo = pname;
        rev = "2a8d0b735328d874a78ca93b2f201649f712a74a";
        hash = "sha256-PSt/SRtemvsoGYNFJ7YLiXGxT8EJe3AhmGwt5Vt79aA=";
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
