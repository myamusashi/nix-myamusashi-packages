{
    lib,
    moduleLocation,
    ...
}: {
    options.flake.homeManagerModules = lib.mkOption {
        type = lib.types.lazyAttrsOf lib.types.deferredModule;
        default = {};
        apply = lib.mapAttrs (
            _name: module: {
                _class = "homeManager";
                _file = "${toString moduleLocation}#homeManagerModules";
                imports = [module];
            }
        );
        description = "Home Manager modules exposed by this flake.";
    };

    config.flake.homeManagerModules = {
        default = import ./hyprboost.nix;
        hyprboost = import ./hyprboost.nix;
    };
}
