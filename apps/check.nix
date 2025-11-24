{ pkgs, lib, helpers, packsLib }:

/*
  Validates that policy files in the current repository match the baseline.

  Usage:
    Direct Consumption (Recommended):
      nix run github:ORG/lineage-baseline#check
      nix run github:ORG/lineage-baseline#check -- --packs editorconfig,license,codeowners
      nix run github:ORG/lineage-baseline#check -- --exclude security,dependabot

    Template-Based Consumption:
      nix run .#check
      nix run .#check -- --packs editorconfig,license,codeowners
      nix run .#check -- --exclude security,dependabot

  Options:
    --packs <list>   Comma-separated list of packs to check
    --exclude <list> Comma-separated list of packs to exclude
    --help           Show this help message

  Environment Variables:
    NIXLINE_PACKS - Comma-separated list of packs to check (fallback)
                    Default: editorconfig,codeowners,security,license,precommit,dependabot

  Exit Codes:
    0 - All policy files are in sync with baseline
    1 - One or more policy files are missing or out of sync

  This app is used by the policy-sync workflow to determine if sync is needed.
*/

pkgs.writeShellApplication {
  name = "nixline-check";

  runtimeInputs = [ pkgs.coreutils pkgs.diffutils pkgs.gnused ];

  text = ''
    set -euo pipefail

    show_usage() {
      cat << 'USAGE_EOF'
          \
       \   |   /
        \  |  /
    ------ + ------
        /  |  \
       /   |   \
          /

      LINEAGE
  Policy Governance via Nix

           ── Lineage Check ──

Validate that policy files in the current repository match the baseline.

Usage:
  nixline-check [OPTIONS]

Options:
  --packs <list>   Comma-separated list of packs to check
  --exclude <list> Comma-separated list of packs to exclude from defaults
  --help           Show this help message

Examples:
  nixline-check
  nixline-check --packs editorconfig,license,codeowners
  nixline-check --exclude security,dependabot

Environment Variables:
  NIXLINE_PACKS - Comma-separated list of packs (fallback if no --packs given)
                  Default: editorconfig,codeowners,security,license,precommit,dependabot
USAGE_EOF
    }

    # Default pack list
    DEFAULT_PACKS="editorconfig,codeowners,security,license,precommit,dependabot"

    # Parse command line arguments
    PACKS_ARG=""
    EXCLUDE_ARG=""

    while [[ $# -gt 0 ]]; do
      case $1 in
        --help|-h)
          show_usage
          exit 0
          ;;
        --packs)
          if [[ -n "''${2:-}" ]]; then
            PACKS_ARG="$2"
            shift 2
          else
            echo "Error: --packs requires a value" >&2
            exit 1
          fi
          ;;
        --exclude)
          if [[ -n "''${2:-}" ]]; then
            EXCLUDE_ARG="$2"
            shift 2
          else
            echo "Error: --exclude requires a value" >&2
            exit 1
          fi
          ;;
        *)
          echo "Error: Unknown option $1" >&2
          show_usage
          exit 1
          ;;
      esac
    done

    # Determine final pack list
    if [[ -n "$PACKS_ARG" ]]; then
      # Use explicit --packs argument
      NIXLINE_PACKS="$PACKS_ARG"
    elif [[ -n "$EXCLUDE_ARG" ]]; then
      # Start with defaults and exclude specified packs
      NIXLINE_PACKS="$DEFAULT_PACKS"
      for exclude in ''${EXCLUDE_ARG//,/ }; do
        NIXLINE_PACKS="$(echo "$NIXLINE_PACKS" | sed "s/\b$exclude\b//g" | sed 's/,,*/,/g' | sed 's/^,\|,$//g')"
      done
    else
      # Use environment variable or default
      NIXLINE_PACKS="''${NIXLINE_PACKS:-$DEFAULT_PACKS}"
    fi

    echo "          \\"
    echo "       \\   |   /"
    echo "        \\  |  /"
    echo "    ------ + ------"
    echo "        /  |  \\"
    echo "       /   |   \\"
    echo "          /"
    echo ""
    echo "      LINEAGE"
    echo "  Policy Governance via Nix"
    echo ""
    echo "       ── Lineage Check ──"
    echo ""

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
