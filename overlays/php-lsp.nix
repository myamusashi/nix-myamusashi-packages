{php-lsp-src}: final: prev: {
    php-lsp = final.rustPlatform.buildRustPackage (
        let
            manifest = (final.lib.importTOML (php-lsp-src + "/Cargo.toml")).package;
        in {
            pname = manifest.name;
            version = manifest.version;

            src = php-lsp-src;

            cargoLock = {
                lockFile = php-lsp-src + "/Cargo.lock";
                outputHashes = {
                    "mir-analyzer-0.72.0" = "sha256-bNbE78j53/YmnmOE4wrZPAkCkQ25/Tej2eT0A+tkbkM=";
                    "mir-codebase-0.72.0" = "sha256-bNbE78j53/YmnmOE4wrZPAkCkQ25/Tej2eT0A+tkbkM=";
                    "mir-issues-0.72.0" = "sha256-bNbE78j53/YmnmOE4wrZPAkCkQ25/Tej2eT0A+tkbkM=";
                    "mir-plugin-0.72.0" = "sha256-bNbE78j53/YmnmOE4wrZPAkCkQ25/Tej2eT0A+tkbkM=";
                    "mir-types-0.72.0" = "sha256-bNbE78j53/YmnmOE4wrZPAkCkQ25/Tej2eT0A+tkbkM=";
                };
            };

            # Test suite shells out to `php -l` (tests/common/php_syntax.rs); without
            # this every php-dependent test panics with "`php` is not in PATH".
            nativeCheckInputs = [final.php];

            buildInputs = final.lib.optionals final.stdenv.isDarwin [final.libiconv];

            meta = {
                description = manifest.description;
                homepage = manifest.repository;
                license = final.lib.licenses.mit;
                mainProgram = "php-lsp";
            };
        }
    );
}
