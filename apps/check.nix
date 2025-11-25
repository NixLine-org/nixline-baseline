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
    LINEAGE_PACKS - Comma-separated list of packs to check (fallback)
                    Default: editorconfig,codeowners,security,license,precommit,dependabot

  Exit Codes:
    0 - All policy files are in sync with baseline
    1 - One or more policy files are missing or out of sync

  This app is used by the policy-sync workflow to determine if sync is needed.
*/

pkgs.writeShellApplication {
  name = "lineage-check";

  runtimeInputs = with pkgs; [
    coreutils
    diffutils
    gnused
    remarshal
    jq
    nix
  ];

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
  lineage-check [OPTIONS]

Options:
  --packs <list>   Comma-separated list of packs to check
  --exclude <list> Comma-separated list of packs to exclude from defaults
  --config <file>  Load configuration from TOML file (default: .lineage.toml)
  --help           Show this help message

Examples:
  lineage-check
  lineage-check --packs editorconfig,license,codeowners
  lineage-check --exclude security,dependabot
  lineage-check --config my-config.toml

Environment Variables:
  LINEAGE_PACKS - Comma-separated list of packs (fallback if no --packs given)
                  Default: editorconfig,codeowners,security,license,precommit,dependabot
USAGE_EOF
    }

    # Default pack list
    DEFAULT_PACKS="editorconfig,codeowners,security,license,precommit,dependabot"

    # Parse command line arguments
    PACKS_ARG=""
    EXCLUDE_ARG=""
    CONFIG_FILE=".lineage.toml"

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
        *)
          echo "Error: Unknown option $1" >&2
          show_usage
          exit 1
          ;;
      esac
    done

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

    # Load and parse configuration
    CONFIG_JSON="{}"
    ORG_NAME="Lineage-org"
    ORG_EMAIL="security@example.com"
    ORG_TEAM="@Lineage-org/maintainers"

    if [[ -f "$CONFIG_FILE" ]]; then
      # Parse TOML to JSON
      CONFIG_JSON=$(remarshal -if toml -of json < "$CONFIG_FILE" 2>/dev/null || echo "{}")

      # Extract organization settings
      ORG_NAME=$(echo "''${CONFIG_JSON}" | jq -r '.organization.name // "Lineage-org"')
      ORG_EMAIL=$(echo "''${CONFIG_JSON}" | jq -r '.organization.email // .organization.security_email // "security@example.com"')
      ORG_TEAM=$(echo "''${CONFIG_JSON}" | jq -r '.organization.default_team // "@Lineage-org/maintainers"')
    fi

    # Determine final pack list
    if [[ -n "$PACKS_ARG" ]]; then
      LINEAGE_PACKS="$PACKS_ARG"
    elif [[ -n "$EXCLUDE_ARG" ]]; then
      LINEAGE_PACKS="$DEFAULT_PACKS"
      for exclude in $(echo "$EXCLUDE_ARG" | tr ',' ' '); do
        LINEAGE_PACKS=$(echo "$LINEAGE_PACKS" | sed "s/\\b$exclude\\b,\\?//g" | sed 's/,,/,/g' | sed 's/^,\\|,$//g')
      done
    else
      # Check for config file pack list
      CONFIG_PACKS=$(echo "$CONFIG_JSON" | jq -r '.packs.enabled[]?' 2>/dev/null | tr '\n' ',' | sed 's/,$//')
      if [[ -n "$CONFIG_PACKS" ]]; then
        LINEAGE_PACKS="$CONFIG_PACKS"
      else
        LINEAGE_PACKS="''${LINEAGE_PACKS:-$DEFAULT_PACKS}"
      fi
    fi

    echo "Validating packs: $LINEAGE_PACKS"
    echo ""

    # Create final configuration JSON for Nix evaluation
    FINAL_CONFIG=$(jq -n \
      --arg orgName "$ORG_NAME" \
      --arg orgEmail "$ORG_EMAIL" \
      --arg orgTeam "$ORG_TEAM" \
      --argjson baseConfig "''${CONFIG_JSON}" \
      '{
        organization: {
          name: $orgName,
          email: $orgEmail,
          security_email: $orgEmail,
          default_team: $orgTeam
        },
        packs: ($baseConfig.packs // {})
      }')

    # Generate expected files using nix eval with configuration
    BASELINE_PATH="${toString ./..}"
    CURRENT_SYSTEM=$(nix eval --impure --expr 'builtins.currentSystem' --raw)
    TEMP_NIX=$(mktemp)
    cat > "$TEMP_NIX" << EOF
let
  pkgs = (builtins.getFlake "$BASELINE_PATH").inputs.nixpkgs.legacyPackages.$CURRENT_SYSTEM;
  lib = pkgs.lib;
  config = builtins.fromJSON '''$FINAL_CONFIG''';

  # Import the packs library with configuration
  packsLib = import $BASELINE_PATH/lib/packs.nix { inherit pkgs lib config; };

  # Parse pack list and get selected packs
  packList = lib.filter (x: x != "") (lib.splitString "," "$LINEAGE_PACKS");
  selectedPacks = lib.filterAttrs (name: _: lib.elem name packList) packsLib.packModules;

  # Get all files from selected packs
  allFiles = lib.foldl' (acc: pack: acc // (pack.files or {})) {} (lib.attrValues selectedPacks);
in
  allFiles
EOF

    # Evaluate expected files and check them
    TEMP_RESULTS=$(mktemp)
    nix eval --no-warn-dirty --impure --file "$TEMP_NIX" --json | jq -r 'to_entries[] | @base64' | while IFS= read -r entry; do
      decoded=$(echo "$entry" | base64 -d)
      file=$(echo "$decoded" | jq -r '.key')
      expected=$(echo "$decoded" | jq -r '.value')

      if [[ ! -f "$file" ]]; then
        echo "[-] Missing $file"
        echo "FAILED" >> "$TEMP_RESULTS"
      elif ! diff -q "$file" <(echo "$expected") >/dev/null 2>&1; then
        echo "[-] Out of sync $file"
        echo "FAILED" >> "$TEMP_RESULTS"
      else
        echo "[+] $file"
      fi
    done

    rm "$TEMP_NIX"

    echo ""

    if [[ -f "$TEMP_RESULTS" ]] && grep -q "FAILED" "$TEMP_RESULTS" 2>/dev/null; then
      rm -f "$TEMP_RESULTS"
      echo "FAILED: Validation failed"
      echo ""
      echo "Run 'nix run .#sync' to fix"
      exit 1
    else
      rm -f "$TEMP_RESULTS"
      echo "All checks passed"
    fi
  '';
}
