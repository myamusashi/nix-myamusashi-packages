{
    lib,
    rustPlatform,
    clang,
    pkg-config,
    dbus,
    pipewire,
    fetchFromGitHub,
}:
rustPlatform.buildRustPackage (finalAttrs: {
    pname = "hyprboost";
    version = "unstable-e9b5c13d";

    src = fetchFromGitHub {
        owner = "Magniquick";
        repo = "hyprboost";
        rev = "e9b5c13d81ace5507609c4a39ecea6a2d5a97909";
        hash = "sha256-uIH5ZoxQ2b+f4wLxV0m0kgfY1QltJ2XlKa9X9ED32kg=";
    };

    cargoLock.lockFile = "${finalAttrs.src}/Cargo.lock";

    nativeBuildInputs = [
        clang
        pkg-config
    ];
    buildInputs = [
        dbus
        pipewire
    ];

    preBuild = ''
        export LIBCLANG_PATH=${lib.getLib clang.cc}/lib
        export BINDGEN_EXTRA_CLANG_ARGS="-I${lib.getLib clang.cc}/include"
    '';

    meta = with lib; {
        description = "Raise CPUWeight for focused, visible and audible apps on Hyprland";
        homepage = "https://github.com/Magniquick/hyprboost";
        license = licenses.mit;
        mainProgram = "hyprboost";
        platforms = platforms.linux;
        maintainers = [];
    };
})
