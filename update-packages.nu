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
    let is_tagged = not ($version_value | str starts-with "unstable-")

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

    if ($content | str contains "cargoHash") {
        print $"  checking cargoHash ..."
        let pname = (extract-field $content "pname")
        let result = (do -i { nix build $".#($pname)" --no-link } | complete)
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
        (ls $"($pkg_dir)/*.nix" | get name)
    } else {
        $names | each {|n| $"($pkg_dir)/($n).nix" }
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
