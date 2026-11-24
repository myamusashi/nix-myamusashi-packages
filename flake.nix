{
    description = "Nix packages playground";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        flake-parts.url = "github:hercules-ci/flake-parts";
        wl-screenrec-fork = {
            url = "github:myamusashi/wl-screenrec";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        neovim-nightly-overlay = {
            url = "github:nix-community/neovim-nightly-overlay";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        loaf-fm = {
            url = "github:m-uvex/loaf-fm";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        mangaDesk = {
            url = "git+https://git.myamusashi.cc/myamusashi/mangaDesk";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        lightauth = {
            url = "git+https://git.myamusashi.cc/myamusashi/lightauth";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        qmlformat-rs = {
            url = "git+https://git.myamusashi.cc/myamusashi/qmlformat-rs";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        omp = {
            url = "github:can1357/oh-my-pi";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        zapfast = {
            url = "github:crmne/zapfast";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        yapfast = {
            url = "github:yapfast/yapfast";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        serein = {
            url = "github:myamusashi/Serein?ref=fix/superseed-hot-reload";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = inputs @ {flake-parts, ...}:
        flake-parts.lib.mkFlake {inherit inputs;} {
            systems = [
                "x86_64-linux"
            ];

            imports = [
                ./modules/packages.nix
                ./modules/devshell.nix
                ./modules/home-manager.nix
                ./modules/overlays.nix
            ];
        };
}
