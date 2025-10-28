{ pkgs, lib, helpers, packsLib }:

/*
  Enhanced sync app with .nixline.toml configuration support.

  Materializes policy files from the baseline into the current repository.

  Usage:
    Direct Consumption (Recommended):
      nix run github:ORG/nixline-baseline#sync
      nix run github:ORG/nixline-baseline#sync -- --packs editorconfig,license,codeowners
      nix run github:ORG/nixline-baseline#sync -- --exclude security,dependabot
      nix run github:ORG/nixline-baseline#sync -- --config .nixline.toml
      nix run github:ORG/nixline-baseline#sync -- --override org.name=MyCompany

    Template-Based Consumption:
      nix run .#sync
      nix run .#sync -- --packs editorconfig,license,codeowners
      nix run .#sync -- --exclude security,dependabot

  Options:
    --packs <list>       Comma-separated list of packs to materialize
    --exclude <list>     Comma-separated list of packs to exclude
    --config <file>      Load configuration from TOML file (default: .nixline.toml)
    --override <key=val> Override configuration values (org.name=MyCompany)
    --dry-run           Show what would be done without making changes
    --help              Show this help message

  Environment Variables:
    NIXLINE_PACKS - Comma-separated list of packs to materialize (fallback)
                    Default: editorconfig,codeowners,security,license,precommit,dependabot

  Configuration File (.nixline.toml):
    [organization]
    name = "MyCompany"
    security_email = "security@mycompany.com"
    default_team = "@MyCompany/maintainers"

    [packs]
    enabled = ["editorconfig", "codeowners", "license"]

    [packs.codeowners]
    rules = [
      { pattern = "*", owners = ["@MyCompany/maintainers"] }
    ]

  This app writes policy files to disk, creating directories as needed. It is
  automatically called by the policy-sync workflow when check detects out-of-sync
  files. Changes are then auto-committed to the repository.
*/

let
  # Import configuration library
  configLib = import ../lib/config.nix { inherit pkgs lib; };

in pkgs.writeShellApplication {
  name = "nixline-sync";

  runtimeInputs = [ pkgs.coreutils pkgs.gnused pkgs.remarshal ];

  text = ''
    set -euo pipefail

    show_usage() {
      cat << 'USAGE_EOF'
╔════════════════════════════════════════════════════════════╗
║                    NixLine Sync (Enhanced)                ║
╚════════════════════════════════════════════════════════════╝

Materialize policy files from the baseline into the current repository.

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
  nixline-sync --packs editorconfig,license,codeowners
  nixline-sync --exclude security,dependabot
  nixline-sync --config my-config.toml
  nixline-sync --override org.name=MyCompany --override org.security_email=sec@myco.com
  nixline-sync --dry-run

Configuration File (.nixline.toml):
  [organization]
  name = "MyCompany"
  security_email = "security@mycompany.com"
  default_team = "@MyCompany/maintainers"

  [packs]
  enabled = ["editorconfig", "codeowners", "license"]

  [packs.codeowners]
  rules = [
    { pattern = "*", owners = ["@MyCompany/maintainers"] },
    { pattern = "*.py", owners = ["@MyCompany/python-team"] }
  ]

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

    # Load configuration if file exists
    ORG_NAME="NixLine-org"
    ORG_EMAIL="security@example.com"
    ORG_TEAM="@NixLine-org/maintainers"

    if [[ -f "$CONFIG_FILE" ]]; then
      echo "Loading configuration from: $CONFIG_FILE"

      # Parse TOML to extract organization settings
      # Note: This is a simplified implementation. In the real implementation,
      # we would use the Nix-based configuration parsing from config.nix
      if command -v remarshal >/dev/null 2>&1; then
        CONFIG_JSON=$(remarshal -if toml -of json < "$CONFIG_FILE" 2>/dev/null || echo "{}")

        # Extract organization values using basic JSON parsing
        if command -v jq >/dev/null 2>&1; then
          ORG_NAME=$(echo "$CONFIG_JSON" | jq -r '.organization.name // "NixLine-org"' 2>/dev/null || echo "NixLine-org")
          ORG_EMAIL=$(echo "$CONFIG_JSON" | jq -r '.organization.security_email // "security@example.com"' 2>/dev/null || echo "security@example.com")
          ORG_TEAM=$(echo "$CONFIG_JSON" | jq -r '.organization.default_team // "@NixLine-org/maintainers"' 2>/dev/null || echo "@NixLine-org/maintainers")

          # Get pack list from config if not overridden by CLI
          if [[ -z "$PACKS_ARG" && -z "$EXCLUDE_ARG" ]]; then
            CONFIG_PACKS=$(echo "$CONFIG_JSON" | jq -r '.packs.enabled[]?' 2>/dev/null | tr '\n' ',' | sed 's/,$//')
            if [[ -n "$CONFIG_PACKS" ]]; then
              NIXLINE_PACKS="$CONFIG_PACKS"
            fi
          fi
        fi
      fi
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
        org.security_email|organization.security_email)
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
    if [[ -n "$PACKS_ARG" ]]; then
      # Use explicit --packs argument
      NIXLINE_PACKS="$PACKS_ARG"
    elif [[ -n "$EXCLUDE_ARG" ]]; then
      # Start with defaults and exclude specified packs
      NIXLINE_PACKS="''${NIXLINE_PACKS:-$DEFAULT_PACKS}"
      for exclude in ''${EXCLUDE_ARG//,/ }; do
        NIXLINE_PACKS="$(echo "$NIXLINE_PACKS" | sed "s/\b$exclude\b//g" | sed 's/,,*/,/g' | sed 's/^,\|,$//g')"
      done
    else
      # Use environment variable, config file, or default
      NIXLINE_PACKS="''${NIXLINE_PACKS:-$DEFAULT_PACKS}"
    fi

    echo "Packs: $NIXLINE_PACKS"

    if [[ "$DRY_RUN" == "true" ]]; then
      echo "DRY RUN: No files will be modified"
    fi
    echo ""

    # Export organization values for pack templates
    export NIXLINE_ORG_NAME="$ORG_NAME"
    export NIXLINE_ORG_EMAIL="$ORG_EMAIL"
    export NIXLINE_ORG_TEAM="$ORG_TEAM"

    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (packName: pack:
      let
        filesScript = lib.concatStringsSep "\n" (lib.mapAttrsToList (path: content: ''
          if echo "$NIXLINE_PACKS" | grep -qw "${packName}"; then
            if [[ "$DRY_RUN" == "true" ]]; then
              echo "[DRY] ${packName}: ${path}"
            else
              mkdir -p "$(dirname "${path}")"
              # Substitute organization variables in content
              FINAL_CONTENT=$(cat << 'NIXLINE_EOF'
${content}
NIXLINE_EOF
)
              # Replace template variables
              FINAL_CONTENT="''${FINAL_CONTENT//\$\{ORG_NAME\}/$NIXLINE_ORG_NAME}"
              FINAL_CONTENT="''${FINAL_CONTENT//\$\{ORG_EMAIL\}/$NIXLINE_ORG_EMAIL}"
              FINAL_CONTENT="''${FINAL_CONTENT//\$\{ORG_TEAM\}/$NIXLINE_ORG_TEAM}"
              echo "$FINAL_CONTENT" > "${path}"
              echo "[+] ${packName}: ${path}"
            fi
          fi
        '') pack.files);
      in filesScript
    ) packsLib.packModules)}

    echo ""
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "Dry run complete - no files were modified"
    else
      echo "Sync complete"
    fi
  '';
}