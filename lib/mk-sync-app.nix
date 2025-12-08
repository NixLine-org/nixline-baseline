{ pkgs, lib, name ? "lineage-sync", packsLoaderSnippet, pkgsExpression ? "import <nixpkgs> {}" }:

pkgs.writeShellApplication {
  inherit name;

  runtimeInputs = with pkgs;
    [ coreutils diffutils gnused remarshal jq nix git ];

  text = ''
    set -euo pipefail

    show_usage() {
      cat << 'USAGE_EOF'
╔════════════════════════════════════════════════════════════╗
║                    Lineage Sync                           ║
╚════════════════════════════════════════════════════════════╝

Materialize policy files with configuration support.

Usage:
  ${name} [OPTIONS]

Options:
  --packs <list>       Comma-separated list of packs to materialize
  --exclude <list>     Comma-separated list of packs to exclude from defaults
  --config <file>      Load configuration from TOML file (default: .lineage.toml)
  --override <key=val> Override configuration values (e.g., org.name=MyCompany)
  --dry-run           Show what would be done without making changes
  --interactive       Ask for confirmation before overwriting changed files
  --backup            Create .bak copies of files before overwriting (default: true)
  --no-backup         Disable backup creation
  --help              Show this help message

Examples:
  ${name}
  ${name} --interactive
  ${name} --config my-config.toml
  ${name} --packs editorconfig,license --override org.name=TestCorp
  ${name} --dry-run

USAGE_EOF
    }

    # Default configuration
    DEFAULT_PACKS="editorconfig,codeowners,security,license,precommit,dependabot"

    # Parse command line arguments
    PACKS_ARG=""
    EXCLUDE_ARG=""
    CONFIG_FILE=".lineage.toml"
    OVERRIDES=()
    DRY_RUN=false
    INTERACTIVE=false
    BACKUP=true

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
        --interactive)
          INTERACTIVE=true
          shift
          ;; 
        --backup)
          BACKUP=true
          shift
          ;; 
        --no-backup)
          BACKUP=false
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
    echo "║                    Lineage Sync                           ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    # Load and parse configuration
    CONFIG_JSON="{}"
    ORG_NAME="Lineage-org"
    ORG_EMAIL="security@example.com"
    ORG_TEAM="@Lineage-org/maintainers"

    if [[ -f "$CONFIG_FILE" ]]; then
      echo "Loading configuration from: $CONFIG_FILE"

      # Parse TOML to JSON
      CONFIG_JSON=$(remarshal -if toml -of json < "$CONFIG_FILE" 2>/dev/null || echo "{}")

      # Extract organization settings
      ORG_NAME=$(echo "''${CONFIG_JSON}" | jq -r '.organization.name // "Lineage-org"')
      ORG_EMAIL=$(echo "''${CONFIG_JSON}" | jq -r '.organization.email // .organization.security_email // "security@example.com"')
      ORG_TEAM=$(echo "''${CONFIG_JSON}" | jq -r '.organization.default_team // "@Lineage-org/maintainers"')

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

    # Determine final pack list (simplified approach)
    if [[ -n "$PACKS_ARG" ]]; then
      LINEAGE_PACKS="$PACKS_ARG"
    elif [[ -n "$EXCLUDE_ARG" ]]; then
      # Apply exclusions to default packs
      LINEAGE_PACKS="$DEFAULT_PACKS"
      for exclude in $(echo "$EXCLUDE_ARG" | tr ',' ' '); do
        LINEAGE_PACKS=$(echo "$LINEAGE_PACKS" | sed "s/\\b$exclude\\b,\?//g" | sed 's/,,/,/g' | sed 's/^,\|,$//g')
      done
    else
      # Check for config file pack list (backwards compatible)
      CONFIG_PACKS=$(echo "$CONFIG_JSON" | jq -r '.packs.enabled[]?' 2>/dev/null | tr '\n' ',' | sed 's/,$//')
      if [[ -n "$CONFIG_PACKS" ]]; then
        LINEAGE_PACKS="$CONFIG_PACKS"
      else
        LINEAGE_PACKS="$DEFAULT_PACKS"
      fi
    fi

    echo "Packs: $LINEAGE_PACKS"

    if [[ "$DRY_RUN" == "true" ]]; then
      echo "DRY RUN: No files will be modified"
    fi
    echo ""

        # Create final configuration JSON for Nix evaluation
        FINAL_CONFIG=$(jq -n --arg orgName "$ORG_NAME" --arg orgEmail "$ORG_EMAIL" --arg orgTeam "$ORG_TEAM" --argjson baseConfig "''${CONFIG_JSON}" '{ organization: { name: $orgName, email: $orgEmail, security_email: $orgEmail, default_team: $orgTeam }, packs: ($baseConfig.packs // {}) }')
        echo "Final configuration for pack generation:"
    echo "$FINAL_CONFIG" | jq .
    echo ""

    # Get current system for flake usage
    CURRENT_SYSTEM=$(nix eval --impure --expr 'builtins.currentSystem' --raw)

    # Create temporary Nix file for file generation
    TEMP_NIX=$(mktemp)
    cat > "$TEMP_NIX" << EOF
let
  pkgs = ${pkgsExpression};
  lib = pkgs.lib;
  config = builtins.fromJSON '''$FINAL_CONFIG''';

  # Load pack modules using the provided snippet
  packModules = ${packsLoaderSnippet};

  # Parse pack list and get selected packs
  packList = lib.filter (x: x != "") (lib.splitString "," "$LINEAGE_PACKS");
  selectedPacks = lib.filterAttrs (name: _: lib.elem name packList) packModules;

  # Get all files from selected packs
  allFiles = lib.foldl' (acc: pack: acc // (pack.files or {})) {} (lib.attrValues selectedPacks);
in
  allFiles
EOF

    STATE_DIR=".lineage/state"

    # Function to perform overwrite (and update state)
    do_overwrite() {
        local file="$1"
        local content="$2"
        
        if [[ -f "$file" && "$BACKUP" == "true" ]]; then
           cp "$file" "$file.bak"
           echo "[Backup] Created $file.bak"
        fi

        mkdir -p "$(dirname "$file")"
        echo "$content" > "$file"
        echo "[+] $file"
        
        # Update state
        local state_file="$STATE_DIR/$file"
        mkdir -p "$(dirname "$state_file")"
        echo "$content" > "$state_file"
    }

    # Function to perform merge
    do_merge() {
        local file="$1"
        local content="$2"
        local state_file="$STATE_DIR/$file"
        
        if [[ ! -f "$state_file" ]]; then
            echo "Warning: No state found for $file, cannot 3-way merge. Falling back to overwrite."
            do_overwrite "$file" "$content"
            return
        fi
        
        local temp_new
        temp_new=$(mktemp)
        echo "$content" > "$temp_new"
        
        if git merge-file -L "current" -L "base" -L "new" "$file" "$state_file" "$temp_new"; then
            echo "[MERGED] $file"
        else
            echo "[CONFLICT] $file - conflict markers added"
        fi
        rm "$temp_new"
        
        # Update state to the NEW baseline content (base for next time)
        mkdir -p "$(dirname "$state_file")"
        echo "$content" > "$state_file"
    }

    if [[ "$DRY_RUN" == "true" ]]; then
      echo "DRY RUN: Checking for changes..."
      nix eval --no-warn-dirty --impure --file "$TEMP_NIX" --json | jq -r 'to_entries[] | @base64' | while IFS= read -r entry;
        do
          decoded=$(echo "$entry" | base64 -d)
          file=$(echo "$decoded" | jq -r '.key')
          content=$(echo "$decoded" | jq -r '.value')

          if [[ -f "$file" ]]; then
              # Check if content differs
              if ! echo "$content" | diff -u "$file" - >/dev/null 2>&1; then
                  echo "--- $file (current)"
                  echo "+++ $file (new)"
                  echo "$content" | diff -u "$file" - || true
              else
                  echo "[UNCHANGED] $file"
              fi
          else
              echo "[NEW] $file"
              echo "Note: New file content not shown in full to save space."
          fi
        done
    else
      echo "Generating files..."
      nix eval --no-warn-dirty --impure --file "$TEMP_NIX" --json | jq -r 'to_entries[] | @base64' | while IFS= read -r entry;
        do
          decoded=$(echo "$entry" | base64 -d)
          file=$(echo "$decoded" | jq -r '.key')
          content=$(echo "$decoded" | jq -r '.value')

          if [[ -f "$file" ]]; then
              # Check if content differs
              if ! echo "$content" | diff -u "$file" - >/dev/null 2>&1;
              then
                  if [[ "$INTERACTIVE" == "true" ]]; then
                      echo ""
                      echo "File $file has changed."
                      echo "$content" | diff -u "$file" - || true
                      
                      while true; do
                          echo -n "Overwrite? [y]es/[n]o/[s]kip/[m]erge: "
                          read -r choice < /dev/tty
                          case "$choice" in
                              y|Y|yes) 
                                  do_overwrite "$file" "$content"
                                  break 
                                  ;;
                              n|N|no|s|S|skip) 
                                  echo "Skipping $file"
                                  break 
                                  ;;
                              m|M|merge)
                                  do_merge "$file" "$content"
                                  break
                                  ;;
                              *)
                                  echo "Invalid choice"
                                  ;;
                          esac
                      done
                  else
                      # Standard behavior:
                      # If we have state, try to merge? Or stick to overwrite?
                      # "Sync" usually means "make it like source".
                      # But 3-way merge is safer.
                      # Let's use 3-way merge if state exists, otherwise overwrite.
                      if [[ -f "$STATE_DIR/$file" ]]; then
                          do_merge "$file" "$content"
                      else
                          do_overwrite "$file" "$content"
                      fi
                  fi
              else
                  # Unchanged content, but ensure state is up to date
                  state_file="$STATE_DIR/$file"
                  mkdir -p "$(dirname "$state_file")"
                  echo "$content" > "$state_file"
                  echo "[UNCHANGED] $file"
              fi
          else
              # New file
              if [[ "$INTERACTIVE" == "true" ]]; then
                  echo ""
                  echo "New file: $file"
                  while true; do
                      echo -n "Create? [y]es/[n]o: "
                      read -r choice < /dev/tty
                      case "$choice" in
                          y|Y|yes) 
                              do_overwrite "$file" "$content"
                              break 
                              ;;
                          n|N|no) 
                              echo "Skipping $file"
                              break 
                              ;;
                          *)
                              echo "Invalid choice"
                              ;;
                      esac
                  done
              else
                  do_overwrite "$file" "$content"
              fi
          fi
        done
    fi
    
    rm "$TEMP_NIX"

    echo ""
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "Dry run complete - no files were modified"
    else
      echo "Sync complete"
    fi
  '';
}
