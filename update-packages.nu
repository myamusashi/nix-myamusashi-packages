#!/usr/bin/env nu
# update-packages.nu — refresh rev/tag + source hash for packages/*.nix
#
# Usage:
#   nu update-packages.nu                    # update every package under packages/
#   nu update-packages.nu csskit quickshell  # update only named packages (by filename, no .nix)
#
# Requires:
#   - `nix` with the `nix-command` experimental feature enabled (for `nix store prefetch-file`)
#   - network access to api.github.com / github.com and whichever Gitea instances
#     your packages point at
#   - optionally $env.GITHUB_TOKEN set, to avoid GitHub API rate limits
#
# Behavior — two modes, detected from the current `version` field:
#   **Tagged mode** — version does NOT start with `unstable-` (e.g. `"0.5.40"`):
#      1. Fetch the latest release tag from GitHub / Gitea.
#      2. Strip a leading `v` for the version field.
#      3. If rev/tag uses interpolation (`"${version}"` / `"v${version}"`), leave it
#         alone — only version changes.  Otherwise write the raw tag name.
#      4. Prefetch the source hash from the tag archive.
#   **Unstable mode** — version starts with `unstable-` (e.g. `"unstable-df91c757"`):
#      1. Fetch the latest commit on the default branch.
#      2. Set version to `unstable-<7-char-sha>`.
#      3. Set rev (or tag for Gitea) to the full commit sha.
#      4. Prefetch the source hash from the commit archive.
#
#   `cargoHash` (and `npmDepsHash`) are auto-resolved by building and parsing
#   the mismatch error.
#
# Known limitations:
#   - Tag ordering relies on the GitHub/Gitea API's default sort (by push/creation
#     date), not semver-aware sort.
#   - Gitea archive URLs assume the standard `/owner/repo/archive/<ref>.tar.gz`
#     layout (true for stock Gitea/Forgejo instances).

def gh-headers [] {
    let token = ($env.GITHUB_TOKEN? | default "")
    if ($token | is-empty) {
        []
    } else {
        ["Authorization" $"Bearer ($token)"]
    }
}

def gh-latest-release-tag [owner: string, repo: string] {
    # Fetch all tags and pick the highest version using semantic sort
    # (git/refs/tags returns by push date, not version — can't trust order).
    try {
        let refs = (http get --headers (gh-headers) $"https://api.github.com/repos/($owner)/($repo)/git/refs/tags")
        let tags = ($refs | each {|r| ($r.ref | str replace "refs/tags/" "") })
        ($tags | str join "\n") | ^sort -V | lines | last
    } catch {
        # fallback: /releases/latest
        let release = (http get --headers (gh-headers) $"https://api.github.com/repos/($owner)/($repo)/releases/latest")
        $release.tag_name
    }
}

def gh-default-branch-sha [owner: string, repo: string] {
    let repo_info = (http get --headers (gh-headers) $"https://api.github.com/repos/($owner)/($repo)")
    let branch = $repo_info.default_branch
    let commit = (http get --headers (gh-headers) $"https://api.github.com/repos/($owner)/($repo)/commits/($branch)")
    $commit.sha
}

def gitea-latest-tag [domain: string, owner: string, repo: string] {
    let tags = (http get $"https://($domain)/api/v1/repos/($owner)/($repo)/tags")
    let names = ($tags | each {|t| $t.name })
    ($names | str join "\n") | ^sort -V | lines | last
}

def gitea-default-branch-sha [domain: string, owner: string, repo: string] {
    let repo_info = (http get $"https://($domain)/api/v1/repos/($owner)/($repo)")
    let branch = $repo_info.default_branch
    let branch_info = (http get $"https://($domain)/api/v1/repos/($owner)/($repo)/branches/($branch)")
    $branch_info.commit.id
}

def prefetch-hash [url: string] {
    let result = (nix store prefetch-file --unpack --hash-type sha256 --json $url | from json)
    $result.hash
}

def extract-field [content: string, key: string] {
    let pattern = ($key + '\s*=\s*"(?P<v>[^"]+)"')
    let matches = ($content | parse -r $pattern)
    if ($matches | is-empty) {
        null
    } else {
        ($matches | first).v
    }
}

# Replace the quoted value on the FIRST line whose key matches `^\s*key\s*=\s*"`.
# Only replaces the first match to avoid overwriting nested hashes (e.g. the hash
# inside cargoDeps, or a second `hash` for a separate fetcher).
def replace-quoted-field [content: string, key: string, new_value: string] {
    let anchored = ('^\s*' + $key + '\s*=\s*"')
    let escaped_value = ($new_value | str replace -a '$' '$$')
    let lines = ($content | lines)
    let match = ($lines | enumerate | where {|it| ($it.item =~ $anchored)} | first)
    if $match == null { return $content }
    let idx = $match.index
    $lines
    | update $idx {|line|
        $line | str replace -r '"[^"]*"' $"\"($escaped_value)\""
    }
    | str join "\n"
}

# Replace the whole `outputHashes = { ... };` attrset (may span multiple lines)
# with a freshly generated block built from `entries` (a list of {name, hash}).
# Preserves the indentation of the `outputHashes` line itself and indents
# entries one level deeper (4 extra spaces, matching this repo's style).
def replace-output-hashes-block [content: string, entries: list] {
    let lines = ($content | lines)
    let start_match = ($lines | enumerate | where {|it| ($it.item =~ '^\s*outputHashes\s*=\s*\{')} | first)
    if $start_match == null { return $content }
    let start_idx = $start_match.index
    let indent = ($lines | get $start_idx | parse -r '^(?<i>\s*)outputHashes' | first | get i)
    # find the matching closing "};" by scanning forward for a line that is
    # just the same indent + "};" (this repo always closes attrsets that way)
    let close_pattern = ('^' + $indent + '\};')
    let end_match = ($lines | enumerate | skip ($start_idx + 1) | where {|it| ($it.item =~ $close_pattern)} | first)
    if $end_match == null { return $content }
    let end_idx = $end_match.index

    let entry_indent = $indent + "    "
    let body = if ($entries | is-empty) {
        []
    } else {
        $entries | each {|e| $"($entry_indent)\"($e.name)\" = \"($e.hash)\";" }
    }
    let new_block = ([$"($indent)outputHashes = {"] | append $body | append $"($indent)};")

    let before = ($lines | first $start_idx)
    let after = ($lines | skip ($end_idx + 1))
    ($before | append $new_block | append $after) | str join "\n"
}

# Parse a Cargo.lock git source string, e.g.
#   git+https://github.com/owner/repo?rev=<sha>#<sha>
#   git+https://github.com/owner/repo?branch=main#<sha>
#   git+https://github.com/owner/repo?tag=v1.0.0#<sha>
# into {url, rev}. The fragment after `#` is always the resolved commit sha,
# so key off that rather than the query param (which varies in shape).
def parse-git-source [source: string] {
    let no_prefix = ($source | str replace -r '^git\+' '')
    let parts = ($no_prefix | split row '#')
    if ($parts | length) < 2 {
        null
    } else {
        let rev = ($parts | last)
        let url = (($parts | first) | split row '?' | first)
        { url: $url, rev: $rev }
    }
}

# Prefetch a git dep and return its SRI sha256 (e.g. "sha256-...."), or null on failure.
def prefetch-git-hash [url: string, rev: string] {
    try {
        let result = (nix run "nixpkgs#nix-prefetch-git" -- --url $url --rev $rev --quiet | complete)
        if $result.exit_code != 0 {
            return null
        }
        let parsed = ($result.stdout | from json)
        let base32 = $parsed.sha256
        let sri = (nix hash convert --to sri --hash-algo sha256 $base32 | str trim)
        if ($sri | is-empty) { null } else { $sri }
    } catch {
        null
    }
}

# Build a package and return the `complete` result, without failing the
# script. Handles the same dep-file special case as the cargoHash block:
# packages under `packages/*/deps/*.nix` aren't exposed as `.#<pname>` flake
# outputs, so they're built via a temp expression + callPackage instead.
def build-package [file: string, pname: string] {
    let is_dep = ($file | str contains "/deps/")
    if $is_dep {
        let tmp = "/tmp/update-dep.nix"
        let root = (pwd)
        let system = (^uname -m | str trim)
        let system = match $system {
            "x86_64" => "x86_64-linux"
            "aarch64" => "aarch64-linux"
            "arm64" => "aarch64-linux"
            "i686" => "i686-linux"
            _ => $"($system)-linux"
        }
        let nix_tpl = 'let
  flake = builtins.getFlake __ROOT__;
  pkgs = flake.inputs.nixpkgs.legacyPackages.__SYSTEM__;
in
  pkgs.callPackage (import __FILE__) {}
'
        let nix_src = ($nix_tpl
            | str replace "__ROOT__" $"\"($root)\""
            | str replace "__SYSTEM__" $system
            | str replace "__FILE__" $"\"($file | path expand)\"")
        $nix_src | save -f $tmp
        (do -i { nix build --impure --no-link -f $tmp } | complete)
    } else {
        (do -i { nix build $".#($pname)" --no-link } | complete)
    }
}

# Resolve every git dependency in a Cargo.lock and rewrite `outputHashes`.
# `archive_url` is the already-computed tarball URL for this package's new
# version (same one used to prefetch the main `hash`), so we extract
# Cargo.lock from the exact same source instead of re-fetching separately.
def update-cargo-lock-output-hashes [file: string, archive_url: string] {
    print "  checking cargoLock.outputHashes ..."
    let pname = (extract-field (open --raw $file) "pname")

    let tmpdir = (mktemp -d)
    print $"  extracting source to ($tmpdir) to read Cargo.lock ..."
    let extract = (do -i { ^curl -fsSL $archive_url | ^tar -xz -C $tmpdir --strip-components=1 } | complete)
    if $extract.exit_code != 0 {
        print "  ⚠ could not extract source archive, skipping outputHashes"
        rm -rf $tmpdir
        return
    }

    let lockfile = $"($tmpdir)/Cargo.lock"
    if not ($lockfile | path exists) {
        print "  ⚠ no Cargo.lock found in source, skipping outputHashes"
        rm -rf $tmpdir
        return
    }

    # `Cargo.lock` has no extension `open` recognizes, so parse explicitly.
    let parsed_lock = (try { open --raw $lockfile | from toml } catch { null })
    if $parsed_lock == null {
        print "  ⚠ could not parse Cargo.lock as TOML, skipping outputHashes"
        rm -rf $tmpdir
        return
    }

    let git_packages = ($parsed_lock.package
        | where {|p| ($p.source? | default "") | str starts-with "git+"}
        | each {|p|
            let parts = (parse-git-source $p.source)
            if $parts == null { null } else {
                { name: $"($p.name)-($p.version)", url: $parts.url, rev: $parts.rev }
            }
        }
        | where {|x| $x != null})

    rm -rf $tmpdir

    if ($git_packages | is-empty) {
        print "  ✓ no git dependencies in Cargo.lock, clearing outputHashes"
        let new_content = (replace-output-hashes-block (open --raw $file) [])
        $"($new_content)\n" | save -f $file
        return
    }

    # dedupe by (url, rev) — a workspace repo can supply several crates at
    # one commit and only needs to be prefetched once
    let unique_sources = ($git_packages | group-by {|p| $"($p.url)#($p.rev)" } | transpose key group | each {|g| $g.group | first })

    print $"  found ($git_packages | length) git dep\(s\) across ($unique_sources | length) unique repo/rev pair\(s\)"

    mut resolved = {}   # "url#rev" -> sri hash
    mut failed = []      # list of {url, rev} that Plan B couldn't resolve

    for src in $unique_sources {
        let key = $"($src.url)#($src.rev)"
        print $"  prefetching ($src.url) @ ($src.rev) ..."
        let hash = (prefetch-git-hash $src.url $src.rev)
        if $hash == null {
            print $"  ⚠ nix-prefetch-git failed for ($src.url), will fall back to build-loop"
            $failed = ($failed | append $src)
        } else {
            print $"  ✓ ($src.rev | str substring 0..7): ($hash)"
            $resolved = ($resolved | insert $key $hash)
        }
    }

    # write whatever Plan B managed to resolve, with a fakeHash placeholder
    # for anything that failed, so Plan A's build-loop has something to work with
    let resolved_snapshot = $resolved
    let entries = ($git_packages | each {|p|
        let key = $"($p.url)#($p.rev)"
        let hash = ($resolved_snapshot | get -o $key)
        { name: $p.name, hash: ($hash | default "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=") }
    })

    let new_content = (replace-output-hashes-block (open --raw $file) $entries)
    $"($new_content)\n" | save -f $file

    if ($failed | is-empty) {
        print "  ✓ outputHashes fully resolved via nix-prefetch-git"
        return
    }

    # --- Plan A fallback: build-loop for whichever entries Plan B couldn't resolve ---
    print $"  falling back to build-loop for ($failed | length) unresolved dep\(s\)"
    mut attempts = 0
    let max_attempts = (($git_packages | length) + 2)  # 1 rebuild per remaining fake hash, plus slack

    while $attempts < $max_attempts {
        $attempts = $attempts + 1
        let result = (build-package $file $pname)
        if $result.exit_code == 0 {
            print "  ✓ outputHashes resolved via build-loop"
            return
        }
        let stderr = ($result.stderr | str trim)

        # case 1: a key is entirely missing from outputHashes (shouldn't happen
        # here since we always seed every known crate, but handled for safety)
        let missing_match = ($stderr | parse -r 'No hash was found while vendoring the git dependency (?<k>[^\s]+)')
        if not ($missing_match | is-empty) {
            let missing_key = ($missing_match | first).k
            print $"  ⚠ missing outputHashes entry for ($missing_key), adding placeholder"
            let cur = (open --raw $file)
            let cur = (replace-output-hashes-block $cur ((extract-output-hash-entries $cur) | append { name: $missing_key, hash: "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=" }))
            $"($cur)\n" | save -f $file
            continue
        }

        # case 2: a fixed-output hash mismatch — fill the first remaining
        # fakeHash-looking entry with the `got:` hash from this error
        let got_match = ($stderr | parse -r 'got:\s*(?<g>sha256-[^\s]+)')
        if ($got_match | is-empty) {
            print '  ⚠ could not parse outputHashes mismatch from build output, showing first 20 lines:'
            $stderr | lines | first 20 | each {|l| print $"  ($l)" }
            return
        }
        let got_hash = ($got_match | first).g
        let cur = (open --raw $file)
        let cur_entries = (extract-output-hash-entries $cur)
        let placeholder_idx = ($cur_entries | enumerate | where {|it| $it.item.hash == "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="} | first)
        if $placeholder_idx == null {
            print "  ⚠ build still failing but no placeholder entries left to fill, giving up"
            return
        }
        let new_entries = ($cur_entries | update $placeholder_idx.index {|e| {name: $e.name, hash: $got_hash} })
        print $"  ✓ ($placeholder_idx.item.name): ($got_hash)"
        let cur = (replace-output-hashes-block $cur $new_entries)
        $"($cur)\n" | save -f $file
    }

    print "  ⚠ gave up on outputHashes after too many build-loop attempts"
}

# Re-read the current `outputHashes = { "name" = "hash"; ... };` block as a
# list of {name, hash} records — used by the build-loop fallback to keep
# editing the same in-progress block across iterations. Scoped to only the
# lines between the outputHashes brace and its matching close, so it can't
# pick up unrelated quoted key/value lines elsewhere in the file.
def extract-output-hash-entries [content: string] {
    let lines = ($content | lines)
    let start_match = ($lines | enumerate | where {|it| ($it.item =~ '^\s*outputHashes\s*=\s*\{')} | first)
    if $start_match == null { return [] }
    let start_idx = $start_match.index
    let indent = ($lines | get $start_idx | parse -r '^(?<i>\s*)outputHashes' | first | get i)
    let close_pattern = ('^' + $indent + '\};')
    let end_match = ($lines | enumerate | skip ($start_idx + 1) | where {|it| ($it.item =~ $close_pattern)} | first)
    if $end_match == null { return [] }
    let end_idx = $end_match.index
    let inner_count = ($end_idx - $start_idx - 1)
    let body = ($lines | skip ($start_idx + 1) | first $inner_count | str join "\n")
    ($body | parse -r '"(?<name>[^"]+)"\s*=\s*"(?<hash>[^"]+)";')
}

def update-package [file: string] {
    let content = (open --raw $file)

    let is_github = ($content | str contains "fetchFromGitHub")
    let is_gitea = ($content | str contains "fetchFromGitea")

    if (not $is_github) and (not $is_gitea) {
        print $"  - skip: no fetchFromGitHub/fetchFromGitea found"
        return
    }

    let owner = (extract-field $content "owner")
    mut repo = (extract-field $content "repo")

    # resolve bare-variable repo = pname; (e.g. 9router.nix, neovide.nix)
    if $repo == null {
        let repo_line = ($content | lines | where ($it | str contains "repo =") | first)
        if ($repo_line | str contains "repo = pname;") {
            $repo = (extract-field $content "pname")
        }
    }

    if ($owner == null) or ($repo == null) {
        print $"  ! could not find owner/repo, skipping"
        return
    }

    let version_value = (extract-field $content "version")
    let is_tagged = ($version_value != null) and (not ($version_value | str starts-with "unstable-"))

    mut new_version = ""
    mut archive_ref = ""       # ref/tag used in the archive URL (full sha or tag name)
    mut rev_key = ""
    mut archive_base = ""
    mut should_update_rev = true
    mut file_rev = ""          # value to write into rev/tag (full sha or tag name)
    mut domain = ""

    if $is_github {
        $rev_key = "rev"
        $archive_base = $"https://github.com/($owner)/($repo)/archive"
    } else {
        $rev_key = "tag"
        $domain = (extract-field $content "domain")
        if ($domain == null) {
            print $"  ! could not find domain for Gitea fetch, skipping"
            return
        }
        $archive_base = $"https://($domain)/($owner)/($repo)/archive"
    }

    if $is_tagged {
        # --- tagged mode: fetch latest release tag ---
        let tag = if $is_github {
            (gh-latest-release-tag $owner $repo)
        } else {
            (gitea-latest-tag $domain $owner $repo)
        }
        print $"  latest tag: ($tag)"
        $new_version = ($tag | str replace -r '^v' '')
        $archive_ref = $tag
        let current_rev = (extract-field $content $rev_key)
        if ($current_rev != null) and ($current_rev | str contains '${version}') {
            $should_update_rev = false
        } else {
            $file_rev = $tag
        }
    } else {
        # --- unstable mode: fetch latest commit on default branch ---
        let sha = if $is_github {
            (gh-default-branch-sha $owner $repo)
        } else {
            (gitea-default-branch-sha $domain $owner $repo)
        }
        let short = ($sha | str substring 0..7)
        print $"  latest commit: ($short)"
        $new_version = $"unstable-($short)"
        $archive_ref = $sha
        $file_rev = $sha
    }

    let archive_url = $"($archive_base)/($archive_ref).tar.gz"
    print $"  hashing ($archive_url) ..."
    let new_hash = (prefetch-hash $archive_url)
    print $"  hash: ($new_hash)"

    mut new_content = $content
    $new_content = (replace-quoted-field $new_content "version" $new_version)
    if $should_update_rev {
        $new_content = (replace-quoted-field $new_content $rev_key $file_rev)
    }
    $new_content = (replace-quoted-field $new_content "hash" $new_hash)

    $"($new_content)\n" | save -f $file
    print $"  ✓ updated ($file)"

    if ($content | str contains "cargoLock") and ($content | str contains "outputHashes") {
        update-cargo-lock-output-hashes $file $archive_url
    }

    if ($content | str contains "cargoHash") {
        print $"  checking cargoHash ..."
        let pname = (extract-field $content "pname")
        let result = (build-package $file $pname)
        if ($result.exit_code == 0) {
            print $"  ✓ cargoHash already correct"
        } else {
            let stderr = ($result.stderr | str trim)
            let cargo_match = ($stderr | parse -r 'got:\s*sha256-(?<g>[^\s]+)')
            let expected = if not ($cargo_match | is-empty) { $"sha256-($cargo_match | first | get g)" } else { null }
            if $expected != null {
                let new_content = (open --raw $file)
                let new_content = (replace-quoted-field $new_content "cargoHash" $expected)
                $"($new_content)\n" | save -f $file
                print $"  ✓ cargoHash updated to ($expected)"
            } else {
                print '  ⚠ could not parse cargoHash from build output, showing first 20 lines:'
                $stderr | lines | first 20 | each {|l| print $"  ($l)" }
            }
        }
    }

    if ($content | str contains "npmDepsHash") {
        print $"  checking npmDepsHash ..."
        let pname = (extract-field $content "pname")
        let pkg_dest = $"packages/($pname)/package-lock.json"
        mut lockfile = ([
            $"packages/($pname)/package-lock.json",
            $"packages/($pname)/npm-shrinkwrap.json",
        ] | where {|p| ($p | path exists) } | first)

        # Extract source archive to check for a lockfile
        let tmpdir = (mktemp -d)
        print $"  extracting source to ($tmpdir) ..."
        ^curl -fsSL $archive_url | ^tar -xz -C $tmpdir --strip-components=1
        let src_lockfile = ([
            $"($tmpdir)/package-lock.json",
            $"($tmpdir)/npm-shrinkwrap.json"
        ] | where {|p| ($p | path exists) } | first)

        if ($lockfile == null) {
            if ($src_lockfile != null) {
                # Found in source but not vendored — copy it to our tree
                $lockfile = $pkg_dest
                mkdir ($lockfile | path dirname)
                cp $src_lockfile $lockfile
                print "  copied lockfile from source into package tree"
            } else {
                # Repo excludes lockfile — generate it with npm install
                print "  no lockfile in source, running npm install --package-lock-only ..."
                let package_json = $"($tmpdir)/package.json"
                if ($package_json | path exists) {
                    ^npm --prefix $tmpdir install --package-lock-only | complete
                    let generated = $"($tmpdir)/package-lock.json"
                    if ($generated | path exists) {
                        $lockfile = $pkg_dest
                        mkdir ($lockfile | path dirname)
                        cp $generated $lockfile
                        print "  generated and copied package-lock.json into package tree"
                    } else {
                        print "  ⚠ npm install did not produce a lockfile, skipping npmDepsHash"
                        rm -rf $tmpdir
                        return
                    }
                } else {
                    print "  ⚠ no package.json in source, skipping npmDepsHash"
                    rm -rf $tmpdir
                    return
                }
            }
        }

        let result = (nix run nixpkgs#prefetch-npm-deps -- $lockfile | complete)
        if ($result.exit_code == 0) {
            let expected = ($result.stdout | str trim)
            let new_content = (open --raw $file)
            let new_content = (replace-quoted-field $new_content "npmDepsHash" $expected)
            $"($new_content)\n" | save -f $file
            print $"  ✓ npmDepsHash updated to ($expected)"
        } else {
            print $"  ⚠ prefetch-npm-deps failed: ($result.stderr | str trim)"
        }
        rm -rf $tmpdir
    }
}

def main [...names: string] {
    let pkg_dir = "packages"
    let files = if ($names | is-empty) {
        # Recursively collect every .nix file under packages/, including deps/
        (^find $pkg_dir -name "*.nix" -type f | lines | sort)
    } else {
        $names | each {|n|
            if ($"($pkg_dir)/($n)" | path exists) {
                # path under packages/ (e.g. Qcm/deps/qr-code-generator.nix)
                $"($pkg_dir)/($n)"
            } else if ($"($pkg_dir)/($n).nix" | path exists) {
                # flat name without dir (e.g. csskit)
                $"($pkg_dir)/($n).nix"
            } else if ($n | path exists) {
                # full path given
                $n
            } else {
                # package dir (e.g. csskit or Qcm/deps/qr-code-generator)
                $"($pkg_dir)/($n)/default.nix"
            }
        }
    }

    for file in $files {
        if not ($file | path exists) {
            print $"==> ($file) — not found, skipping"
            continue
        }
        print $"==> ($file)"
        try {
            update-package $file
        } catch { |err|
            print -e $"  ! failed: ($err.msg)"
        }
    }
}
