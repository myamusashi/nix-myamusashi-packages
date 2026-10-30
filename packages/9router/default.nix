{
    lib,
    buildNpmPackage,
    fetchFromGitHub,
}:
buildNpmPackage rec {
    pname = "9router";
    version = "0.5.112";

    src = fetchFromGitHub {
        owner = "decolua";
        repo = pname;
        rev = "v${version}";
        hash = "sha256-FZ8sDiEVtDHXS5754dLtm/J/yd17J4kkHoHqb2ihLU8=";
    };

    npmDepsFetcherVersion = 2;
    makeCacheWritable = true;
    npmFlags = ["--legacy-peer-deps"];
    npmDepsHash = "sha256-8aP4G1plMC1Vxrl440nBXbL6AYF0OTQef8scUqkUQOc=";

    postPatch = ''
        cp ${./package-lock.json} package-lock.json
        substituteInPlace src/app/layout.js \
            --replace-fail 'import { Inter } from "next/font/google";' 'const Inter = () => ({ variable: "--font-inter", subsets: ["latin"] });'
    '';

    installPhase = ''
        runHook preInstall

        mkdir -p $out/lib/9router/app
        shopt -s dotglob
        cp -r .next/standalone/* $out/lib/9router/app/
        cp -r .next/standalone/. $out/lib/9router/app/
        cp -r .next/static $out/lib/9router/app/.next/static
        shopt -u dotglob

        cp -r public $out/lib/9router/app/public
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
