{
    lib,
    buildNpmPackage,
    fetchFromGitHub,
}:
buildNpmPackage rec {
    pname = "9router";
    version = "0.5.40";

    src = fetchFromGitHub {
        owner = "decolua";
        repo = pname;
        rev = "v${version}";
        hash = "sha256-5X3NDLRy5jC9D3xn2wlm4Svb6Ly5YOMrVyOyiA134Fs=";
    };

    npmDepsHash = "sha256-duddNBnN33e4LtmiFy1lLOzLLdzlJr9kSJ/wBseIlow=";

    postPatch = ''
        cp ${./9router/package-lock.json} package-lock.json
        substituteInPlace src/app/layout.js \
            --replace-fail 'import { Inter } from "next/font/google";' 'const Inter = () => ({ variable: "--font-inter", subsets: ["latin"] });'
    '';

    installPhase = ''
        runHook preInstall

        mkdir -p $out/lib/9router/app
        shopt -s dotglob
        cp -r .next/standalone/* $out/lib/9router/app/
        shopt -u dotglob
        cp custom-server.js $out/lib/9router/app/
        cp cli/cli.js $out/lib/9router/
        cp cli/package.json $out/lib/9router/
        cp -r cli/hooks $out/lib/9router/
        cp -r cli/src $out/lib/9router/

        mkdir -p $out/lib/9router/node_modules
        cp -r node_modules/* $out/lib/9router/node_modules/

        mkdir -p $out/bin
        ln -s $out/lib/9router/cli.js $out/bin/9router

        runHook postInstall
    '';

    meta = with lib; {
        description = "Unlimited FREE AI coding. Connect Claude Code, Codex, Cursor, Cline, Copilot, Antigravity to FREE Claude/GPT/Gemini via 40+ providers. Auto-fallback, RTK -40% tokens, never hit limits.";
        license = licenses.mit;
        mainProgram = "9router";
    };
}
