{
    config,
    lib,
    pkgs,
    ...
}: let
    cfg = config.programs.hyprboost;
in {
    options.programs.hyprboost = {
        enable = lib.mkEnableOption "hyprboost, which boosts the CPUWeight of the focused, visible and audible Hyprland apps";

        package = lib.mkOption {
            type = lib.types.package;
            default = pkgs.callPackage ../packages/hyprboost {};
            defaultText = lib.literalExpression "pkgs.callPackage ../packages/hyprboost {}";
            description = "The hyprboost package to run.";
        };

        service = {
            after = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = ["graphical-session.target"];
                description = ''
                    Units to order hyprboost after. The graphical session is where
                    Hyprland's event socket comes to life.
                '';
            };

            partOf = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = ["graphical-session.target"];
                description = ''
                    Units hyprboost is stopped together with. Weight changes are
                    runtime-only, so logging out must undo them.
                '';
            };

            wantedBy = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = ["graphical-session.target"];
                description = "Targets hyprboost is enabled into.";
            };

            importEnvironment = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [
                    "HYPRLAND_INSTANCE_SIGNATURE"
                    "WAYLAND_DISPLAY"
                ];
                description = ''
                    Variables pulled into the systemd --user manager environment
                    through `ImportEnvironment`. hyprboost locates Hyprland's event
                    socket at
                    `$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock`
                    and exits without it. Set to `[ ]` if the session already
                    exports these.
                '';
            };

            extraConfig = lib.mkOption {
                type = lib.types.attrsOf (lib.types.either (lib.types.bool) (lib.types.listOf lib.types.str));
                default = {};
                example = lib.literalExpression ''
                    {
                      Service.Type = "notify"; # use systemd notification instead
                    }
                '';
                description = ''
                    Extra freeform unit configuration, merged into the generated
                    `Unit`, `Service` and `Install` sections.
                '';
            };
        };
    };

    config = lib.mkIf cfg.enable {
        systemd.user.services.hyprboost =
            {
                Unit = {
                    Description = "Boost CPUWeight of focused, visible and audible apps under Hyprland";
                    After = cfg.service.after;
                    PartOf = cfg.service.partOf;
                };

                Service = {
                    Type = "simple";
                    ExecStart = lib.getExe cfg.package;
                    Restart = "on-failure";
                    RestartSec = "2";
                };

                Install.WantedBy = cfg.service.wantedBy;
            }
            // cfg.service.extraConfig;

        systemd.user.settings.Manager.ImportEnvironment = cfg.service.importEnvironment;
    };
}
