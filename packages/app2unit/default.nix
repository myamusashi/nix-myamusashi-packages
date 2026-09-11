{
    lib,
    stdenvNoCC,
    fetchFromGitHub,
    makeWrapper,
    bash,
    systemd,
    coreutils,
    findutils,
    gnugrep,
    git,
    gnused,
    scdoc,
    gawk,
    libnotify,
}:
stdenvNoCC.mkDerivation rec {
    pname = "app2unit";
    version = "unstable-47e23ec6";

    src = fetchFromGitHub {
        owner = "Vladimir-csp";
        repo = "app2unit";
        tag = "v${version}";
        hash = "sha256-TIY+/9ekGub+10uyqXy5aYU+2NLysMtaQnD1PIjBCFA=";
    };

    nativeBuildInputs = [makeWrapper];

    buildInputs = [
        bash
        systemd
        coreutils
        findutils
        gnugrep
        gnused
        gawk
        scdoc
        git
        libnotify
    ];

    dontBuild = true;

    installPhase = ''
        runHook preInstall

        mkdir -p $out/bin
        cp app2unit $out/bin/
        chmod +x $out/bin/app2unit

        wrapProgram $out/bin/app2unit \
          --prefix PATH : ${lib.makeBinPath [
            bash
            systemd
            coreutils
            findutils
            gnugrep
            gnused
            gawk
            scdoc
            git
            libnotify
        ]}

        runHook postInstall
    '';

    meta = with lib; {
        description = "Create systemd user units for applications";
        longDescription = ''
            app2unit is a tool to create systemd user units for applications,
            allowing them to be managed by systemd user services.
        '';
        homepage = "https://github.com/Vladimir-csp/app2unit";
        license = licenses.gpl3Plus;
        maintainers = [myamusashi];
        platforms = platforms.linux;
        mainProgram = "app2unit";
    };
}
