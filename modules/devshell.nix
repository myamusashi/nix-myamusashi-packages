{...}: {
    perSystem = {pkgs, ...}: {
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
}
