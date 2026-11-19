{
    config,
    inputs,
    ...
}: {
    # Overlay for hotfixes and missing dependencies on upstream flake packages.
    flake.overlays.default = final: _prev: let
        inherit (final.stdenv.hostPlatform) system;
    in {
        zapfast = inputs.zapfast.packages.${system}.default.overrideAttrs (oldAttrs: {
            buildInputs =
                (oldAttrs.buildInputs or [])
                ++ [
                    final.openssl
                    final.sqlcipher
                ];
        });

        yapfast = inputs.yapfast.packages.${system}.default.overrideAttrs (oldAttrs: {
    src = inputs.yapfast;
    cargoDeps = final.rustPlatform.importCargoLock {
        lockFile = "${inputs.yapfast}/Cargo.lock";
        outputHashes = {
            "const_panic-0.2.15" = "sha256-zEmo8lKncnNhn2LL5aRT95AZD/LqjmNcRg2qTKXLcic=";
            "matrix-rtc-bridge-0.4.0-rc.1" = "sha256-Zm+5xARhyrix22Ihz2fesWkwg21FaT/eqi240eT1lnQ=";
            "matrix-sdk-0.19.1" = "sha256-MzEIaDxJVssAiTd2r7qRSdkZvD+IYpC71shuJU5TATE=";
        };
    };
    preBuild = "";
    buildInputs = (oldAttrs.buildInputs or []) ++ [final.aws-lc];
});
    };

    perSystem = {inputs', ...}: {
        _module.args.pkgs = inputs'.nixpkgs.legacyPackages.appendOverlays [
            config.flake.overlays.default
        ];
    };
}
