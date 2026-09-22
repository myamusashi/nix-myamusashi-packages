{inputs, ...}: let
    inherit
        (inputs)
        hyprland
        php-lsp
        aerothemeplasma-nix
        neovim-nightly-overlay
        wl-screenrec-fork
        omp
        zapfast
        ;

    discoverPackages = {
        callPackage,
        directory,
        exclude ? [
            "9router"
            "headroom-ai"
            "hyprland-scroll-overview"
            "hypr-dynamic-cursors"
            "ladybird"
        ],
    }: let
        entries = builtins.readDir directory;
        isPkg = name: type:
            type
            == "directory"
            && builtins.pathExists (directory + "/${name}/default.nix")
            && !(builtins.elem name exclude);
        pkgNames = builtins.filter (n: isPkg n entries.${n}) (builtins.attrNames entries);
    in
        builtins.listToAttrs (map (name: {
            inherit name;
            value = callPackage (directory + "/${name}") {};
        })
        pkgNames);
in {
    perSystem = {
        pkgs,
        system,
        ...
    }: let
        pkgsWithHyprland = pkgs.extend (final: prev: {
            hyprland = hyprland.packages.${system}.hyprland;
        });

        pkgsWithNeovim = pkgs.extend neovim-nightly-overlay.overlays.default;

        atpPkgs = aerothemeplasma-nix.packages.${system} or {};

        pkgsWithPhplsp = pkgs.extend (import ../overlays/php-lsp.nix {
            php-lsp-src = php-lsp.outPath;
        });

        ompPkgs = omp.packages.${system}.default.overrideAttrs (oldAttrs: {
            patches =
                (oldAttrs.patches or [])
                ++ [
                    ./oh-my-pi-satisfied-opencode-free-tier.patch
                ];
        });
        phplsp = pkgsWithPhplsp.php-lsp;
        zapfastPkgs = zapfast.packages.${system}.default;
        wlScrnFork = wl-screenrec-fork.packages.${system}.default;
    in {
        formatter = pkgs.alejandra;

        packages =
            (discoverPackages {
                inherit (pkgsWithHyprland) callPackage;
                directory = ../packages;
            })
            // {inherit (pkgsWithNeovim) neovim;}
            // atpPkgs
            // {
                wl-screenrec-fork = wlScrnFork;
                php-lsp = phplsp;
                omp = ompPkgs;
                zapfast = zapfastPkgs;
            };
    };
}
