{
    lib,
    python3,
    fetchFromGitHub,
    rustPlatform,
    ast-grep,
    makeWrapper,
}:
python3.pkgs.buildPythonPackage rec {
    pname = "headroom-ai";
    version = "0.32.0";
    pyproject = true;

    src = fetchFromGitHub {
        owner = "chopratejas";
        repo = "headroom";
        rev = "v${version}";
        hash = "sha256-7+ul+rco4HvI3ar6Y9JvfBiFem8IeBwnBEGUcj/d9xU=";
    };

    cargoDeps = rustPlatform.fetchCargoVendor {
        inherit pname version src;
        hash = "sha256-7+ul+rco4HvI3ar6Y9JvfBiFem8IeBwnBEGUcj/d9xU=";
    };

    nativeBuildInputs = [
        rustPlatform.cargoSetupHook
        rustPlatform.maturinBuildHook
        makeWrapper
    ];

    pythonRelaxDeps = true;

    propagatedBuildInputs = with python3.pkgs; [
        tiktoken
        pydantic
        litellm
        click
        rich
        opentelemetry-api
        pyyaml
        tomli
        tomlkit
        fastapi
        uvicorn
        orjson
        httpx
        openai
        mcp
        magika
        zstandard
        websockets
        onnxruntime
        transformers
        watchdog
        sqlite-vec
    ];

    postFixup = ''
        wrapProgram $out/bin/headroom --prefix PATH : ${lib.makeBinPath [ ast-grep ]}
    '';

    dontCheckRuntimeDeps = true;
    doCheck = false;

    pythonImportsCheck = ["headroom"];

    meta = with lib; {
        description = "Context optimization layer for LLM applications — proxy, compression, caching";
        homepage = "https://github.com/chopratejas/headroom";
        license = licenses.asl20;
        mainProgram = "headroom";
    };
}
