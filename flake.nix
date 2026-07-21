{
    description = "Nix packages playground";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        flake-parts.url = "github:hercules-ci/flake-parts";
        aerothemeplasma-nix = {
            url = "github:myamusashi/aerothemeplasma-nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        neovim-nightly-overlay = {
            url = "github:nix-community/neovim-nightly-overlay";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        aquamarine = {
            url = "github:hyprwm/aquamarine";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        hyprutils = {
            url = "github:hyprwm/hyprutils";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        hyprcursor = {
            url = "github:hyprwm/hyprcursor";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        hyprgraphics = {
            url = "github:hyprwm/hyprgraphics";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        hyprland-protocols = {
            url = "github:hyprwm/hyprland-protocols";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        hyprland-guiutils = {
            url = "github:hyprwm/hyprland-guiutils";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        hyprlang = {
            url = "github:hyprwm/hyprlang";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        hyprwayland-scanner = {
            url = "github:hyprwm/hyprwayland-scanner";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        hyprwire = {
            url = "github:hyprwm/hyprwire";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        hyprlock = {
            url = "github:hyprwm/hyprlock";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        hypridle = {
            url = "github:hyprwm/hypridle";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        hyprsunset = {
            url = "github:hyprwm/hyprsunset";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        hyprqt6engine = {
            url = "github:hyprwm/hyprqt6engine";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        hyprtoolkit = {
            url = "github:hyprwm/hyprtoolkit";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        hyprpicker = {
            url = "github:hyprwm/hyprpicker";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        hyprpwcenter = {
            url = "github:hyprwm/hyprpwcenter";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        kwin-effects-forceblur = {
            url = "github:taj-ny/kwin-effects-forceblur";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = inputs @ {flake-parts, aerothemeplasma-nix, neovim-nightly-overlay, ...}:
        flake-parts.lib.mkFlake {inherit inputs;} {
            systems = [
                "x86_64-linux"
                "aarch64-linux"
            ];

            perSystem = {pkgs, system, ...}: let
                atpPkgs = aerothemeplasma-nix.packages.${system} or {};
                pkgsWithNeovim = pkgs.extend neovim-nightly-overlay.overlays.default;
            in {
                formatter = pkgs.alejandra;

                packages = (pkgs.lib.packagesFromDirectoryRecursive {
                    inherit (pkgs) callPackage;
                    directory = ./packages;
                }) // atpPkgs // { neovim = pkgsWithNeovim.neovim; };

                devShells.default = pkgs.mkShell {
                    buildInputs = with pkgs; [
                        alejandra
                        nil
                        statix
                        nixd
                        nushell
                    ];
                    shellHook = ''
                        echo "Nix packages development environment"
                    '';
                };
            };
        };
}
