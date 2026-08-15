{
    stdenvNoCC,
    fetchurl,
    lib,
    autoPatchelfHook,
    installShellFiles,
    gcc,
    unzip,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "yazi";
    version = "26.8.15";

    src = fetchurl {
        url = "https://github.com/sxyazi/yazi/releases/download/v${finalAttrs.version}/yazi-x86_64-unknown-linux-gnu.zip";
        hash = "sha256-zGfreZFVDC+UB82lLT9a8JN2J6pohOfemaBPzwWYB+A=";
    };

    nativeBuildInputs = [
        autoPatchelfHook
        installShellFiles
        unzip
    ];

    buildInputs = [gcc.cc.lib];

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
        runHook preInstall

        install -Dm755 yazi $out/bin/yazi
        install -Dm755 ya $out/bin/ya

        installShellCompletion --cmd ya \
          --nushell completions/ya.nu \
          --bash    completions/ya.bash \
          --fish    completions/ya.fish \
          --zsh     completions/_ya

        installShellCompletion --cmd yazi \
          --nushell completions/yazi.nu \
          --bash    completions/yazi.bash \
          --fish    completions/yazi.fish \
          --zsh     completions/_yazi

        runHook postInstall
    '';

    meta = {
        description = "Blazing fast terminal file manager written in Rust, based on async I/O";
        homepage = "https://github.com/sxyazi/yazi";
        changelog = "https://github.com/sxyazi/yazi/releases/tag/v${finalAttrs.version}";
        license = lib.licenses.mit;
        platforms = ["x86_64-linux"];
        maintainers = with lib.maintainers; [
            eljamm
            khaneliman
            linsui
            matthiasbeyer
            uncenter
            xyenon
        ];
        mainProgram = "yazi";
    };
})
