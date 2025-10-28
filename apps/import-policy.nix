{ pkgs, lib }:

/*
  Imports existing policy files from a consumer repository into pack format.

  Usage:
    Direct Consumption:
      nix run github:ORG/nixline-baseline#import-policy -- --file <path>
      nix run github:ORG/nixline-baseline#import-policy -- --auto

    Template-Based Consumption:
      nix run .#import-policy -- --file <path>
      nix run .#import-policy -- --auto

  This utility helps baseline maintainers convert existing policy files into
  NixLine packs. It recognizes common policy files (LICENSE, SECURITY.md,
  .editorconfig, CODEOWNERS, dependabot.yml) and generates corresponding pack
  files in packs/ directory.

  Use --auto to scan and import all recognized files in the current directory,
  or --file to import a specific file with optional --pack name override.
*/

pkgs.writeShellApplication {
  name = "nixline-import-policy";

  runtimeInputs = [ pkgs.coreutils ];

  text = ''
    set -euo pipefail

    # Mapping of file paths to pack names
    declare -A FILE_TO_PACK=(
      [".editorconfig"]="editorconfig"
      ["LICENSE"]="license"
      ["SECURITY.md"]="security"
      [".github/CODEOWNERS"]="codeowners"
      [".github/dependabot.yml"]="dependabot"
    )

    # Mapping of pack names to file paths
    declare -A PACK_TO_FILE=(
      ["editorconfig"]=".editorconfig"
      ["license"]="LICENSE"
      ["security"]="SECURITY.md"
      ["codeowners"]=".github/CODEOWNERS"
      ["dependabot"]=".github/dependabot.yml"
    )

    show_usage() {
      cat << EOF
╔════════════════════════════════════════════════════════════╗
║              NixLine Policy Importer                       ║
╚════════════════════════════════════════════════════════════╝

Import existing policy files into NixLine pack format.

Usage:
  nixline-import-policy --file <path>
  nixline-import-policy --pack <name> --file <path>
  nixline-import-policy --auto

Options:
  --file PATH    Path to existing policy file
  --pack NAME    Pack name (auto-detected if not specified)
  --auto         Auto-import all recognized files in current directory

Supported files:
  .editorconfig              → editorconfig pack
  LICENSE                    → license pack
  SECURITY.md                → security pack
  .github/CODEOWNERS         → codeowners pack
  .github/dependabot.yml     → dependabot pack

Examples:
  # Import specific file (auto-detect pack)
  nixline-import-policy --file .editorconfig

  # Import with explicit pack name
  nixline-import-policy --pack editorconfig --file .editorconfig

  # Auto-import all recognized files
  nixline-import-policy --auto

Output:
  Generated pack files are written to packs/ directory
EOF
    }

    generate_pack() {
      local pack_name="$1"
      local file_path="$2"
      local file_content

      if [[ ! -f "$file_path" ]]; then
        echo "Error: File not found: $file_path" >&2
        return 1
      fi

      file_content=$(cat "$file_path")

      # Escape single quotes in content for Nix
      file_content="'''"$'\n'"$file_content"$'\n'"'''"

      local target_file
      target_file="''${PACK_TO_FILE[$pack_name]}"

      cat > "packs/$pack_name.nix" << EOF
{ pkgs, lib }:

#
# $(echo "$pack_name" | tr '[:lower:]' '[:upper:]') PACK
#
# Imported from existing $file_path
# You can customize this pack by editing the content below.
#

{
  files = {
    "$target_file" = $file_content;
  };

  checks = [];
}
EOF

      echo "✓ Generated packs/$pack_name.nix from $file_path"
    }

    # Parse arguments
    MODE=""
    FILE_PATH=""
    PACK_NAME=""

    while [[ $# -gt 0 ]]; do
      case $1 in
        --help|-h)
          show_usage
          exit 0
          ;;
        --auto)
          MODE="auto"
          shift
          ;;
        --file)
          FILE_PATH="$2"
          shift 2
          ;;
        --pack)
          PACK_NAME="$2"
          shift 2
          ;;
        *)
          echo "Unknown option: $1" >&2
          show_usage
          exit 1
          ;;
      esac
    done

    # Create packs directory if it doesn't exist
    mkdir -p packs

    if [[ "$MODE" == "auto" ]]; then
      echo "╔════════════════════════════════════════════════════════════╗"
      echo "║           Auto-importing policy files                      ║"
      echo "╚════════════════════════════════════════════════════════════╝"
      echo ""

      FOUND=0
      for file_path in "''${!FILE_TO_PACK[@]}"; do
        if [[ -f "$file_path" ]]; then
          pack_name="''${FILE_TO_PACK[$file_path]}"
          generate_pack "$pack_name" "$file_path"
          FOUND=$((FOUND + 1))
        fi
      done

      echo ""
      if [[ $FOUND -eq 0 ]]; then
        echo "No recognized policy files found in current directory."
        echo "Run with --help to see supported files."
        exit 1
      else
        echo "Successfully imported $FOUND policy file(s)."
        echo ""
        echo "Next steps:"
        echo "  1. Review generated files in packs/"
        echo "  2. Customize pack content as needed"
        echo "  3. Commit packs to your baseline repository"
      fi

    elif [[ -n "$FILE_PATH" ]]; then
      echo "╔════════════════════════════════════════════════════════════╗"
      echo "║              Importing policy file                         ║"
      echo "╚════════════════════════════════════════════════════════════╝"
      echo ""

      # Auto-detect pack name if not provided
      if [[ -z "$PACK_NAME" ]]; then
        # Try to match file path
        if [[ -v "FILE_TO_PACK[$FILE_PATH]" ]]; then
          PACK_NAME="''${FILE_TO_PACK[$FILE_PATH]}"
          echo "Auto-detected pack: $PACK_NAME"
        else
          # Try basename match
          BASENAME=$(basename "$FILE_PATH")
          if [[ -v "FILE_TO_PACK[$BASENAME]" ]]; then
            PACK_NAME="''${FILE_TO_PACK[$BASENAME]}"
            echo "Auto-detected pack: $PACK_NAME"
          else
            echo "Error: Could not auto-detect pack for $FILE_PATH" >&2
            echo "Please specify --pack NAME explicitly" >&2
            exit 1
          fi
        fi
      fi

      # Validate pack name
      if [[ ! -v "PACK_TO_FILE[$PACK_NAME]" ]]; then
        echo "Error: Unknown pack name: $PACK_NAME" >&2
        echo "Supported packs: ''${!PACK_TO_FILE[*]}" >&2
        exit 1
      fi

      generate_pack "$PACK_NAME" "$FILE_PATH"

      echo ""
      echo "Next steps:"
      echo "  1. Review packs/$PACK_NAME.nix"
      echo "  2. Customize content as needed"
      echo "  3. Commit to your baseline repository"

    else
      show_usage
      exit 1
    fi
  '';
}
