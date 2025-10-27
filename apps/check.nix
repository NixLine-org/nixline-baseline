{ pkgs, lib, helpers, packsLib }:

/*
  Validates that policy files in the current repository match the baseline.

  Usage:
    nix run .#check

  Environment Variables:
    NIXLINE_PACKS - Comma-separated list of packs to check
                    Default: editorconfig,codeowners,security,license,dependabot

  Exit Codes:
    0 - All policy files are in sync with baseline
    1 - One or more policy files are missing or out of sync

  This app is used by the policy-sync workflow to determine if sync is needed.
*/

pkgs.writeShellApplication {
  name = "nixline-check";

  runtimeInputs = [ pkgs.coreutils pkgs.diffutils ];

  text = ''
    set -euo pipefail

    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                   NixLine Check                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    # Get requested packs from environment (default: persistent packs only)
    NIXLINE_PACKS="''${NIXLINE_PACKS:-editorconfig,codeowners,security,license,precommit,dependabot}"

    echo "Validating packs: $NIXLINE_PACKS"
    echo ""

    failed=0

    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (packName: pack:
      let
        checksScript = lib.concatStringsSep "\n" (lib.mapAttrsToList (path: content: ''
          if echo "$NIXLINE_PACKS" | grep -qw "${packName}"; then
            if [[ ! -f "${path}" ]]; then
              echo "[-] ${packName}: Missing ${path}"
              failed=1
            elif ! diff -q "${path}" <(cat << 'NIXLINE_EOF'
            ${content}
            NIXLINE_EOF
            ) >/dev/null 2>&1; then
              echo "[-] ${packName}: Out of sync ${path}"
              failed=1
            else
              echo "[+] ${packName}: ${path}"
            fi
          fi
        '') pack.files);
      in checksScript
    ) packsLib.packModules)}

    echo ""

    if [[ $failed -eq 1 ]]; then
      echo "FAILED: Validation failed"
      echo ""
      echo "Run 'nix run .#sync' to fix"
      exit 1
    else
      echo "All checks passed"
    fi
  '';
}
