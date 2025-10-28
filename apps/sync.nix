{ pkgs, lib, helpers, packsLib }:

/*
  Enhanced sync app with proper configuration passing to parameterized packs.

  This implementation follows nix.dev best practices:
  - Separates configuration (JSON) from logic (Nix expressions)
  - Uses nix eval for runtime configuration passing
  - Maintains reproducibility through explicit dependencies
*/

pkgs.writeShellApplication {
  name = "nixline-sync";

  runtimeInputs = with pkgs; [
    coreutils
    gnused
    remarshal
    jq
    nix  # Required for nix eval
  ];

  text = ''
    set -euo pipefail

    show_usage() {
      cat << 'USAGE_EOF'
╔════════════════════════════════════════════════════════════╗
║                    NixLine Sync (Enhanced)                ║
╚════════════════════════════════════════════════════════════╝

Materialize policy files from the baseline with configuration support.

Usage:
  nixline-sync [OPTIONS]

Options:
  --packs <list>       Comma-separated list of packs to materialize
  --exclude <list>     Comma-separated list of packs to exclude from defaults
  --config <file>      Load configuration from TOML file (default: .nixline.toml)
  --override <key=val> Override configuration values (e.g., org.name=MyCompany)
  --dry-run           Show what would be done without making changes
  --help              Show this help message

Examples:
  nixline-sync
  nixline-sync --config my-config.toml
  nixline-sync --packs editorconfig,license --override org.name=TestCorp
  nixline-sync --dry-run

USAGE_EOF
    }

    # Default configuration
    DEFAULT_PACKS="editorconfig,codeowners,security,license,precommit,dependabot"

    # Parse command line arguments
    PACKS_ARG=""
    EXCLUDE_ARG=""
    CONFIG_FILE=".nixline.toml"
    OVERRIDES=()
    DRY_RUN=false

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
        --config)
          if [[ -n "''${2:-}" ]]; then
            CONFIG_FILE="$2"
            shift 2
          else
            echo "Error: --config requires a value" >&2
            exit 1
          fi
          ;;
        --override)
          if [[ -n "''${2:-}" ]]; then
            OVERRIDES+=("$2")
            shift 2
          else
            echo "Error: --override requires a value" >&2
            exit 1
          fi
          ;;
        --dry-run)
          DRY_RUN=true
          shift
          ;;
        *)
          echo "Error: Unknown option $1" >&2
          show_usage
          exit 1
          ;;
      esac
    done

    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                 NixLine Sync (Enhanced)                   ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    # Load and parse configuration
    CONFIG_JSON="{}"
    ORG_NAME="NixLine-org"
    ORG_EMAIL="security@example.com"
    ORG_TEAM="@NixLine-org/maintainers"

    if [[ -f "$CONFIG_FILE" ]]; then
      echo "Loading configuration from: $CONFIG_FILE"

      # Parse TOML to JSON
      CONFIG_JSON=$(remarshal -if toml -of json < "$CONFIG_FILE" 2>/dev/null || echo "{}")

      # Extract organization settings
      ORG_NAME=$(echo "$CONFIG_JSON" | jq -r '.organization.name // "NixLine-org"')
      ORG_EMAIL=$(echo "$CONFIG_JSON" | jq -r '.organization.email // .organization.security_email // "security@example.com"')
      ORG_TEAM=$(echo "$CONFIG_JSON" | jq -r '.organization.default_team // "@NixLine-org/maintainers"')

      echo "Organization: $ORG_NAME"
      echo "Security Email: $ORG_EMAIL"
      echo "Default Team: $ORG_TEAM"
      echo ""
    else
      echo "No configuration file found ($CONFIG_FILE), using defaults"
      echo ""
    fi

    # Apply CLI overrides
    for override in "''${OVERRIDES[@]}"; do
      key=$(echo "$override" | cut -d'=' -f1)
      value=$(echo "$override" | cut -d'=' -f2-)

      case "$key" in
        org.name|organization.name)
          ORG_NAME="$value"
          echo "Override: Organization name = $ORG_NAME"
          ;;
        org.security_email|organization.security_email|org.email|organization.email)
          ORG_EMAIL="$value"
          echo "Override: Security email = $ORG_EMAIL"
          ;;
        org.default_team|organization.default_team)
          ORG_TEAM="$value"
          echo "Override: Default team = $ORG_TEAM"
          ;;
        *)
          echo "Warning: Unknown override key: $key"
          ;;
      esac
    done

    # Determine final pack list
    NIXLINE_PACKS="$DEFAULT_PACKS"

    if [[ -n "$PACKS_ARG" ]]; then
      NIXLINE_PACKS="$PACKS_ARG"
    elif [[ -n "$EXCLUDE_ARG" ]]; then
      # Apply exclusions
      for exclude in $(echo "$EXCLUDE_ARG" | tr ',' ' '); do
        NIXLINE_PACKS=$(echo "$NIXLINE_PACKS" | sed "s/\\b$exclude\\b,\\?//g" | sed 's/,,/,/g' | sed 's/^,\\|,$//g')
      done
    else
      # Check for config file pack list
      CONFIG_PACKS=$(echo "$CONFIG_JSON" | jq -r '.packs.enabled[]?' 2>/dev/null | tr '\n' ',' | sed 's/,$//')
      if [[ -n "$CONFIG_PACKS" ]]; then
        NIXLINE_PACKS="$CONFIG_PACKS"
      fi
    fi

    echo "Packs: $NIXLINE_PACKS"

    if [[ "$DRY_RUN" == "true" ]]; then
      echo "DRY RUN: No files will be modified"
    fi
    echo ""

    # Create final configuration JSON for Nix evaluation
    FINAL_CONFIG=$(jq -n \
      --arg orgName "$ORG_NAME" \
      --arg orgEmail "$ORG_EMAIL" \
      --arg orgTeam "$ORG_TEAM" \
      --argjson baseConfig "$CONFIG_JSON" \
      '{
        organization: {
          name: $orgName,
          email: $orgEmail,
          security_email: $orgEmail,
          default_team: $orgTeam
        },
        packs: ($baseConfig.packs // {})
      }')

    echo "Final configuration for pack generation:"
    echo "$FINAL_CONFIG" | jq .
    echo ""

    # Generate files using nix eval with configuration
    # Use the baseline path from the Nix store build
    BASELINE_PATH="${toString ./..}"

    if [[ "$DRY_RUN" == "true" ]]; then
      echo "DRY RUN: Would generate the following files:"

      # Create temporary Nix file with variable substitution
      TEMP_NIX=$(mktemp)
      cat > "$TEMP_NIX" << EOF
let
  pkgs = import <nixpkgs> {};
  lib = pkgs.lib;
  config = builtins.fromJSON '''$FINAL_CONFIG''';

  # Import the packs library with configuration
  packsLib = import $BASELINE_PATH/lib/packs.nix { inherit pkgs lib config; };

  # Parse pack list and get selected packs
  packList = lib.filter (x: x != "") (lib.splitString "," "$NIXLINE_PACKS");
  selectedPacks = lib.filterAttrs (name: _: lib.elem name packList) packsLib.packModules;

  # Get all files from selected packs
  allFiles = lib.foldl' (acc: pack: acc // (pack.files or {})) {} (lib.attrValues selectedPacks);
in
  lib.attrNames allFiles
EOF

      nix eval --no-warn-dirty --impure --file "$TEMP_NIX" --json | jq -r '.[]' | while read -r file; do
        echo "[DRY] $file"
      done
      rm "$TEMP_NIX"
    else
      echo "Generating files..."

      # Create temporary Nix file for file generation
      TEMP_NIX=$(mktemp)
      cat > "$TEMP_NIX" << EOF
let
  pkgs = import <nixpkgs> {};
  lib = pkgs.lib;
  config = builtins.fromJSON '''$FINAL_CONFIG''';

  # Import the packs library with configuration
  packsLib = import $BASELINE_PATH/lib/packs.nix { inherit pkgs lib config; };

  # Parse pack list and get selected packs
  packList = lib.filter (x: x != "") (lib.splitString "," "$NIXLINE_PACKS");
  selectedPacks = lib.filterAttrs (name: _: lib.elem name packList) packsLib.packModules;

  # Get all files from selected packs
  allFiles = lib.foldl' (acc: pack: acc // (pack.files or {})) {} (lib.attrValues selectedPacks);
in
  allFiles
EOF

      nix eval --no-warn-dirty --impure --file "$TEMP_NIX" --json | jq -r 'to_entries[] | @base64' | while IFS= read -r entry; do
        decoded=$(echo "$entry" | base64 -d)
        file=$(echo "$decoded" | jq -r '.key')
        content=$(echo "$decoded" | jq -r '.value')

        mkdir -p "$(dirname "$file")"
        echo "$content" > "$file"
        echo "[+] $file"
      done
      rm "$TEMP_NIX"
    fi

    echo ""
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "Dry run complete - no files were modified"
    else
      echo "Sync complete"
    fi
  '';
}