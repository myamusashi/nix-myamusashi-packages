{inputs, ...}: let
    inherit (inputs.nixpkgs) lib;

    inherit
        (inputs)
        yapfast
        neovim-nightly-overlay
        wl-screenrec-fork
        omp
        zapfast
        serein
        mangaDesk
        qmlformat-rs
        lightauth
        loaf-fm
        ;

    discoverPackages = {
        callPackage,
        directory,
        exclude ? [
            "ladybird"
        ],
    }: let
        entries = builtins.readDir directory;

        isPackageDirectory = name: type:
            type
            == "directory"
            && builtins.pathExists (directory + "/${name}/default.nix")
            && !(builtins.elem name exclude);
    in
        builtins.mapAttrs
        (name: _: callPackage (directory + "/${name}") {})
        (lib.filterAttrs isPackageDirectory entries);
in {
    perSystem = {
        pkgs,
        system,
        ...
    }: let
        pkgsWithNeovim = pkgs.extend neovim-nightly-overlay.overlays.default;

        ompPkgs = omp.packages.${system}.default;
        zapfastPkgs = zapfast.packages.${system}.default.overrideAttrs (oldAttrs: {
            buildInputs = (oldAttrs.buildInputs or []) ++ [pkgs.openssl];
            nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [pkgs.pkg-config];
        });
        sereinPkgs = serein.packages.${system}.default;
        wlScrnFork = wl-screenrec-fork.packages.${system}.default;
        mangaDeskPkgs = mangaDesk.packages.${system}.default.overrideAttrs (oldAttrs: {
            buildInputs = (oldAttrs.buildInputs or []) ++ [pkgs.sqlite];
        });
        qmlformatRsPkgs = qmlformat-rs.packages.${system}.default;
        lightauthPkgs = lightauth.packages.${system}.default.overrideAttrs (oldAttrs: {
            buildInputs = (oldAttrs.buildInputs or []) ++ [pkgs.libgit2];
            nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [pkgs.pkg-config];
        });
        loafFmPkgs = loaf-fm.packages.${system}.default;
        yapfastPkgs = yapfast.packages.${system}.default.overrideAttrs (_: {
            # The upstream derivation forces system AWS-LC, which is not in its
            # build environment. Let aws-lc-sys compile its bundled source instead.
            AWS_LC_SYS_USE_SYSTEM = "0";
        });
    in {
        formatter = pkgs.alejandra;

        packages =
            (discoverPackages {
                inherit (pkgs) callPackage;
                directory = ../packages;
            })
            // {inherit (pkgsWithNeovim) neovim;}
            // {
                wl-screenrec-fork = wlScrnFork;
                yapfast = yapfastPkgs;
                omp = ompPkgs;
                zapfast = zapfastPkgs;
                serein = sereinPkgs;
                mangaDesk = mangaDeskPkgs;
                qmlformat-rs = qmlformatRsPkgs;
                lightauth = lightauthPkgs;
                loaf-fm = loafFmPkgs;
            };
    };
}
