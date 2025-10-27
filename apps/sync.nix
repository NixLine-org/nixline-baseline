{ pkgs, lib, helpers, packsLib }:

/*
  Materializes policy files from the baseline into the current repository.

  Usage:
    nix run .#sync
    nix run .#sync -- --packs editorconfig,license,codeowners
    nix run .#sync -- --exclude security,dependabot

  Options:
    --packs <list>   Comma-separated list of packs to materialize
    --exclude <list> Comma-separated list of packs to exclude
    --help           Show this help message

  Environment Variables:
    NIXLINE_PACKS - Comma-separated list of packs to materialize (fallback)
                    Default: editorconfig,codeowners,security,license,precommit,dependabot

  This app writes policy files to disk, creating directories as needed. It is
  automatically called by the policy-sync workflow when check detects out-of-sync
  files. Changes are then auto-committed to the repository.
*/

pkgs.writeShellApplication {
  name = "nixline-sync";

  runtimeInputs = [ pkgs.coreutils pkgs.gnused ];

  text = ''
    set -euo pipefail

    show_usage() {
      cat << 'USAGE_EOF'
╔════════════════════════════════════════════════════════════╗
║                    NixLine Sync                            ║
╚════════════════════════════════════════════════════════════╝

Materialize policy files from the baseline into the current repository.

Usage:
  nixline-sync [OPTIONS]

Options:
  --packs <list>   Comma-separated list of packs to materialize
  --exclude <list> Comma-separated list of packs to exclude from defaults
  --help           Show this help message

Examples:
  nixline-sync
  nixline-sync --packs editorconfig,license,codeowners
  nixline-sync --exclude security,dependabot

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

    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                    NixLine Sync                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    echo "Packs: $NIXLINE_PACKS"
    echo ""

    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (packName: pack:
      let
        filesScript = lib.concatStringsSep "\n" (lib.mapAttrsToList (path: content: ''
          if echo "$NIXLINE_PACKS" | grep -qw "${packName}"; then
            mkdir -p "$(dirname "${path}")"
            cat > "${path}" << 'NIXLINE_EOF'
${content}
NIXLINE_EOF
            echo "[+] ${packName}: ${path}"
          fi
        '') pack.files);
      in filesScript
    ) packsLib.packModules)}

    echo ""
    echo "Sync complete"
  '';
}
