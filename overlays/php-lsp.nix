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
                allowBuiltinFetchGit = true;
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
