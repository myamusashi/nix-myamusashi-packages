{inputs, ...}: let
    inherit
        (inputs)
        hyprland
        aerothemeplasma-nix
        neovim-nightly-overlay
        wl-screenrec-fork
        ;

    discoverPackages = {
        callPackage,
        directory,
    }: let
        entries = builtins.readDir directory;
        isPkg = name: type:
            type
            == "directory"
            && builtins.pathExists (directory + "/${name}/default.nix");
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
            // {wl-screenrec-fork = wlScrnFork;};
    };
}
