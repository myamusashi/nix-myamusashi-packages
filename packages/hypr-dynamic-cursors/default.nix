{
    stdenvNoCC,
    hyprland,
    gcc14,
    fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
    pname = "hypr-dynamic-cursors";
    version = "unstable-e62e326e";

    src = fetchFromGitHub {
        owner = "VirtCode";
        repo = pname;
        rev = "e62e326e6302f82d933c885d0df1d8ccb9830093";
        hash = "sha256-VNA0EGCQCPcedIDv82VKnm94cJzgErONQgkrkYp4ldc=";
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
