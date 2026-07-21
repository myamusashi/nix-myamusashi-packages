#!/usr/bin/env nu
# update-packages.nu — refresh rev + source hash for packages/*.nix to latest commit
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
# Behavior:
#   - Always tracks the latest commit on the default branch.
#   - Version format: `unstable-<7-char-sha>`.
#   - Only touches `hash = "...";` (the fetchFromGitHub/fetchFromGitea source
#     hash). `cargoHash` is auto-resolved by building and parsing the mismatch error.
#
# Known limitations (kept simple on purpose):
#   - Assumes one `owner`/`repo`/`domain`/`rev`/`tag`/`version`/`hash` per file.
#   - Tag ordering uses natural string sort, not semver-aware sort — fine for
#     plain "vX.Y.Z" tags, may pick wrong result on more exotic tag schemes.
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

def gh-default-branch-sha [owner: string, repo: string] {
    let repo_info = (http get --headers (gh-headers) $"https://api.github.com/repos/($owner)/($repo)")
    let branch = $repo_info.default_branch
    let commit = (http get --headers (gh-headers) $"https://api.github.com/repos/($owner)/($repo)/commits/($branch)")
    $commit.sha
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

# Replace the quoted value on the (single) line whose key matches `^\s*key\s*=\s*"`.
# Anchoring on line-start + key avoids `hash` accidentally matching inside `cargoHash`.
def replace-quoted-field [content: string, key: string, new_value: string] {
    let anchored = ('^\s*' + $key + '\s*=\s*"')
    let escaped_value = ($new_value | str replace -a '$' '$$')
    $content
    | lines
    | each {|line|
        if ($line =~ $anchored) {
            ($line | str replace -r '"[^"]*"' $"\"($escaped_value)\"")
        } else {
            $line
        }
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
    let repo = (extract-field $content "repo")

    if ($owner == null) or ($repo == null) {
        print $"  ! could not find owner/repo, skipping"
        return
    }

    mut new_version = ""
    mut concrete_rev = ""   # actual ref used to build the archive URL (real tag or full sha)
    mut file_rev = ""      # what gets written into the rev/tag field in the .nix file
    mut archive_base = ""
    mut rev_key = ""

    if $is_github {
        $rev_key = "rev"
        $archive_base = $"https://github.com/($owner)/($repo)/archive"
        let sha = (gh-default-branch-sha $owner $repo)
        let short = ($sha | str substring 0..7)
        print $"  latest commit: ($short)"
        $new_version = $"unstable-($short)"
        $concrete_rev = $sha
        $file_rev = $sha
    } else {
        $rev_key = "tag"
        let domain = (extract-field $content "domain")
        if ($domain == null) {
            print $"  ! could not find domain for Gitea fetch, skipping"
            return
        }
        $archive_base = $"https://($domain)/($owner)/($repo)/archive"
        let sha = (gitea-default-branch-sha $domain $owner $repo)
        let short = ($sha | str substring 0..7)
        print $"  latest commit: ($short)"
        $new_version = $"unstable-($short)"
        $concrete_rev = $sha
        $file_rev = $sha
    }

    let archive_url = $"($archive_base)/($concrete_rev).tar.gz"
    print $"  hashing ($archive_url) ..."
    let new_hash = (prefetch-hash $archive_url)
    print $"  hash: ($new_hash)"

    mut new_content = $content
    $new_content = (replace-quoted-field $new_content "version" $new_version)
    $new_content = (replace-quoted-field $new_content $rev_key $file_rev)
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
