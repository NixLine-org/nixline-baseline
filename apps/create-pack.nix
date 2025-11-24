{ pkgs, lib }:

/*
  Creates new policy packs with template structure or from governance repositories.

  Usage:
    Single Pack Creation:
      nix run github:ORG/nixline-baseline#create-pack -- <pack-name>
      nix run .#create-pack -- <pack-name>

    Batch Creation from Repository:
      nix run .#create-pack -- --from-repo <github-url>
      nix run .#create-pack -- --from-repo /path/to/local/repo

    Information:
      nix run .#create-pack -- --list-examples
      nix run .#create-pack -- --help

  The enhanced version can discover governance files from repositories using the
  NixLine Baseline Importer and create multiple pack files with real content.

  Examples:
    nix run .#create-pack -- flake8
    nix run .#create-pack -- --from-repo https://github.com/cisagov/lineage
    nix run .#create-pack -- --from-repo /tmp/my-governance-repo
*/

pkgs.writeShellApplication {
  name = "nixline-create-pack";

  runtimeInputs = with pkgs; [
    coreutils
    git
    nix
  ];

  text = ''
    set -euo pipefail

    main() {
      show_usage() {
      cat << 'USAGE_EOF'
╔════════════════════════════════════════════════════════════╗
║                   Lineage Pack Creator                     ║
╚════════════════════════════════════════════════════════════╝

Create policy packs for your NixLine baseline from templates or governance repositories.

Pack files are automatically organized by ecosystem:
  • universal/    - Cross-language packs (editorconfig, license, etc.)
  • python/       - Python ecosystem packs (flake8, bandit, etc.)
  • javascript/   - JavaScript/Node.js packs (eslint, jest, etc.)
  • rust/         - Rust ecosystem packs (future)
  • go/           - Go ecosystem packs (future)

Usage:
  nixline-create-pack <pack-name>                    Create single pack from template
  nixline-create-pack --from-repo <repo-url>         Import all packs from governance repo
  nixline-create-pack --from-repo <local-path>       Import all packs from local repo
  nixline-create-pack --list-examples                Show example pack configurations

Options:
  <pack-name>           Name of pack to create (e.g., flake8, prettier)
  --from-repo <source>  GitHub URL or local path to governance repository
  --list-examples       Show common pack configuration examples
  --help, -h           Show this help message

Single Pack Examples:
  # Create a flake8 pack from template
  nixline-create-pack flake8

  # Create a prettier pack from template
  nixline-create-pack prettier

Batch Import Examples:
  # Import all governance files from CISA lineage
  nixline-create-pack --from-repo https://github.com/cisagov/lineage

  # Import from local governance repository
  nixline-create-pack --from-repo /path/to/governance-repo

  # Import from another organization's governance
  nixline-create-pack --from-repo https://github.com/myorg/governance

The --from-repo option discovers governance files automatically and creates
pack files with actual configuration content, not just templates.

Pack files will be created in packs/ directory.
USAGE_EOF
    }

    list_examples() {
      cat << 'EXAMPLES_EOF'
Common Pack Examples:

# Python Development
- flake8         Python linting configuration (.flake8)
- black          Python code formatting (.black)
- pytest         Python testing configuration (pytest.ini)
- mypy           Python type checking (mypy.ini)
- bandit         Python security linting (.bandit.yml)
- isort          Python import sorting (.isort.cfg)
- coverage       Code coverage reporting (.coveragerc)

# JavaScript/Node Development
- prettier       Code formatting for JS/TS (.prettierrc)
- prettierignore Prettier ignore patterns (.prettierignore)
- eslint         JavaScript linting (.eslintrc.js)
- jest           JavaScript testing (jest.config.js)
- tsconfig       TypeScript configuration (tsconfig.json)

# General Development
- dockerfile     Dockerfile linting rules (.hadolint.yaml)
- yamllint       YAML file linting (.yamllint)
- markdownlint   Markdown linting rules (.mdlrc)
- gitattributes  Git attributes configuration (.gitattributes)
- ansible        Ansible linting rules (.ansible-lint)

# CI/CD & DevOps
- sonarqube      SonarQube configuration (sonar-project.properties)
- codecov        Code coverage configuration (.codecov.yml)
- renovate       Renovate dependency updates (.renovaterc.json)
- precommit      Pre-commit hooks (.pre-commit-config.yaml)

Each pack should define files to materialize and optionally checks to run.
EXAMPLES_EOF
    }

    # Parse arguments
    PACK_NAME=""
    FROM_REPO=""
    MODE="single"

    if [[ $# -eq 0 ]]; then
      show_usage
      exit 1
    fi

    while [[ $# -gt 0 ]]; do
      case $1 in
        --help|-h)
          show_usage
          exit 0
          ;;
        --list-examples|--examples)
          list_examples
          exit 0
          ;;
        --from-repo)
          if [[ $# -lt 2 ]]; then
            echo "Error: --from-repo requires a repository URL or path" >&2
            exit 1
          fi
          FROM_REPO="$2"
          MODE="batch"
          shift 2
          ;;
        *)
          if [[ "$MODE" == "single" ]]; then
            PACK_NAME="$1"
          else
            echo "Error: Unexpected argument '$1' when using --from-repo" >&2
            exit 1
          fi
          shift
          ;;
      esac
    done

    # Validation and execution based on mode
    if [[ "$MODE" == "single" ]]; then
      if [[ -z "$PACK_NAME" ]]; then
        echo "Error: Pack name is required" >&2
        show_usage
        exit 1
      fi

      # Validate pack name
      if [[ ! "$PACK_NAME" =~ ^[a-z0-9]+$ ]]; then
        echo "Error: Pack name must contain only lowercase letters and numbers" >&2
        exit 1
      fi

      create_single_pack "$PACK_NAME"
      validate_pack_input "$PACK_NAME"
    else
      if [[ -z "$FROM_REPO" ]]; then
        echo "Error: Repository URL or path is required with --from-repo" >&2
        exit 1
      fi

      create_packs_from_repo "$FROM_REPO"
    fi
  }

  # Determine pack category based on name and ecosystems
  get_pack_category() {
    local pack_name="$1"
    local ecosystems="$2"

    # Language-specific pack detection
    case "$pack_name" in
      bandit|flake8|pytest|isort|black|mypy|pylint)
        echo "python" ;;
      eslint|jest|typescript|webpack|babel|rollup)
        echo "javascript" ;;
      clippy|rustfmt|cargo)
        echo "rust" ;;
      golint|gofmt|govet)
        echo "go" ;;
      *)
        # Universal packs for governance, formatting, etc.
        echo "universal" ;;
    esac
  }

  create_single_pack() {
    local pack_name="$1"
    local ecosystems="''${2:-}"
    local category
    category=$(get_pack_category "$pack_name" "$ecosystems")
    local pack_file="packs/$category/$pack_name.nix"

    if [[ -f "$pack_file" ]]; then
      echo "Error: Pack $pack_name already exists at $pack_file" >&2
      exit 1
    fi

    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                Creating NixLine Pack                       ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Pack name: $pack_name"
    echo "File path: $pack_file"
    echo ""

    # Create organized packs directories if they don't exist
    mkdir -p "packs/$category"

    # Generate pack template using shared library
    cat > "$pack_file" << EOF
{ pkgs, lib, config ? {} }:

#
# $(echo "$pack_name" | tr '[:lower:]' '[:upper:]') PACK
#
# This pack provides $pack_name configuration for all repositories that enable it.
#
# To enable this pack in a consumer repository:
# 1. Add "$pack_name" to the enabled packs list in .nixline.toml
# 2. Run 'nix run .#sync' to materialize the configuration files
# 3. Commit the generated files to your repository
#
# USAGE PATTERNS:
# - For parameterized packs (customizable): use template-utils.createParameterizedPack
# - For static packs (fixed content): use template-utils.createStaticPack
#

let
  utils = import ../../lib/pack-utils.nix { inherit pkgs lib; };
in

# OPTION 1: Static Pack (no customization)
utils.template-utils.createStaticPack {
  packName = "$pack_name";
  ecosystem = "$category";
  description = "$pack_name configuration pack";

  files = {
    # TODO: Define configuration files to materialize
    # Example:
    # "$pack_name.conf" = '''
    #   # $pack_name configuration
    #   # Add your configuration content here
    # ''';
  };

  customChecks = [
    # TODO: Add custom validation checks (optional)
    # Standard file existence and syntax checks are added automatically
    # Example:
    # (utils.toolValidationCheck "$pack_name" ".$pack_name" "--check")
  ];
}

# OPTION 2: Parameterized Pack (customizable via .nixline.toml)
# Uncomment this and comment out the static pack above if you need customization:
#
# utils.template-utils.createParameterizedPack {
#   packName = "$pack_name";
#   ecosystem = "$category";
#   description = "$pack_name configuration pack";
#
#   configDefaults = {
#     # TODO: Define default configuration values
#     # setting1 = "default_value";
#     # setting2 = true;
#   };
#
#   fileGenerators = packConfig: orgConfig: {
#     # TODO: Generate files using packConfig and orgConfig
#     # Example:
#     # ".$pack_name" = '''
#     #   # Organization: YOUR_ORG_NAME
#     #   # Setting: YOUR_SETTING_VALUE
#     # ''';
#   };
#
#   customChecks = [
#     # TODO: Add custom validation checks
#   ];
# } config
EOF

    echo "✓ Created $pack_file"
    echo ""
    echo "Next steps:"
    echo "  1. Edit $pack_file to define your configuration files"
    echo "  2. Add \"$pack_name\" to enabled packs in .nixline.toml"
    echo "  3. Run 'nix run .#sync' in consumer repos to materialize the files"
    echo "  4. Test with 'nix run .#check' to validate the configuration"
    echo ""
    echo "Example files you might want to create:"
    echo "  - $pack_name.conf (main configuration file)"
    echo "  - $${pack_name}rc (resource configuration)"
    echo "  - config/$pack_name.yml (YAML configuration)"
  }

  create_packs_from_repo() {
    local repo_source="$1"
    local temp_dir=""

    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║           Importing Governance Repository                  ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Repository: $repo_source"
    echo "Discovering governance files..."
    echo ""

    # Handle GitHub URL vs local path
    if [[ "$repo_source" =~ ^https://github.com/ ]]; then
      if ! temp_dir=$(mktemp -d); then
        echo "Error: Failed to create temporary directory" >&2
        exit 1
      fi
      trap 'rm -rf "$temp_dir"' EXIT

      echo "Cloning repository..."
      if ! git clone --depth 1 "$repo_source" "$temp_dir/repo" >/dev/null 2>&1; then
        echo "Error: Failed to clone repository $repo_source" >&2
        exit 1
      fi
      repo_path="$temp_dir/repo"
    else
      if [[ ! -d "$repo_source" ]]; then
        echo "Error: Directory $repo_source does not exist" >&2
        exit 1
      fi
      repo_path="$repo_source"
    fi

    # Use the importer to discover governance files
    echo "Analyzing governance files with NixLine Baseline Importer..."

    # Use the local importer (assume running from nixline-baseline repo)
    local importer_path="/Users/jason/code/nixline-org/nixline-baseline/tools/baseline-importer"

    # Discover governance files using the importer
    local discovery_result
    if ! discovery_result=$(nix eval --impure --json "$importer_path"#lib.x86_64-darwin.importFromSource --apply 'f: let result = f '"$repo_path"'; in result._meta'); then
      echo "Error: Failed to analyze governance repository" >&2
      exit 1
    fi

    local discovered_files ecosystems file_count parameterized_packs direct_packs all_pack_names
    discovered_files=$(echo "$discovery_result" | nix run nixpkgs#jq -- -r '.discoveredFiles[]')
    ecosystems=$(echo "$discovery_result" | nix run nixpkgs#jq -- -r '.detectedEcosystems[]?' | tr '\n' ' ')
    file_count=$(echo "$discovery_result" | nix run nixpkgs#jq -- -r '.fileCount')
    parameterized_packs=$(echo "$discovery_result" | nix run nixpkgs#jq -- -r '.parameterizedPacks[]?' | tr '\n' ' ')
    direct_packs=$(echo "$discovery_result" | nix run nixpkgs#jq -- -r '.directPacks[]?' | tr '\n' ' ')
    all_pack_names=$(echo "$discovery_result" | nix run nixpkgs#jq -- -r '.allPackNames[]?' | tr '\n' ' ')

    echo "Discovery complete!"
    echo "Found $file_count governance files"
    if [[ -n "$ecosystems" ]]; then
      echo "Detected ecosystems: $ecosystems"
    fi
    if [[ -n "$parameterized_packs" ]]; then
      echo "Using parameterized packs: $parameterized_packs"
    fi
    if [[ -n "$direct_packs" ]]; then
      echo "Creating direct packs: $direct_packs"
    fi
    echo ""

    # Create organized packs directories if they don't exist
    mkdir -p packs/{universal,python,javascript,rust,go}

    local created_packs=()
    local skipped_packs=()

    # Only create pack files for direct packs (parameterized packs already exist)
    if [[ -n "$direct_packs" ]]; then
      while IFS= read -r pack_name; do
        if [[ -z "$pack_name" ]]; then
          continue
        fi

        local category
        category=$(get_pack_category "$pack_name" "$ecosystems")
        local pack_file="packs/$category/$pack_name.nix"

        if [[ -f "$pack_file" ]]; then
          echo "Skipping $pack_name (already exists)"
          skipped_packs+=("$pack_name")
          continue
        fi

        # Find the corresponding governance file for this pack
        local governance_file
        local pack_base="$${pack_name%config}"
        governance_file=$(echo "$discovered_files" | grep -E "\\.?$pack_base" | head -1)

        echo "Creating pack: $pack_name from $governance_file"
        create_pack_from_governance_file "$repo_path" "$governance_file" "$pack_name" "$pack_file"
        validate_pack_input "$pack_name"
        created_packs+=("$pack_name")
      done <<< "$(echo "$direct_packs" | tr ' ' '\n')"
    fi

    # Show completion report
    show_completion_report "$parameterized_packs" "$direct_packs" "$all_pack_names"
  }

  generate_pack_name_from_file() {
    local filename="$1"
    local basename
    basename=$(basename "$filename")

    # Remove leading dots and file extensions, convert to lowercase
    basename=$(echo "$basename" | sed 's/^\.//; s/\.[^.]*$//' | tr '[:upper:]' '[:lower:]' | tr -d -- '-_.')

    # Truncate if too long
    # shellcheck disable=SC2000
    if [ "$(echo "$basename" | wc -c)" -gt 21 ]; then
      basename=$(echo "$basename" | head -c20)
    fi

    echo "$basename"
  }

  create_pack_from_governance_file() {
    local repo_path="$1"
    local governance_file="$2"
    local pack_name="$3"
    local pack_file="$4"

    local file_content
    file_content=$(cat "$repo_path/$governance_file")

    # Generate pack file with actual content using shared library
    cat > "$pack_file" << EOF
{ pkgs, lib, config ? {} }:

#
# $(echo "$pack_name" | tr '[:lower:]' '[:upper:]') PACK
#
# Generated from $governance_file by NixLine Baseline Importer
# Original governance repository integration
#

let
  utils = import ../../lib/pack-utils.nix { inherit pkgs lib; };
in

utils.template-utils.createStaticPack {
  packName = "$pack_name";
  ecosystem = "universal";
  description = "Generated from $governance_file";

  files = {
    "$governance_file" = '''
$file_content    ''';
  };

  customChecks = [
    # Standard checks (file existence, syntax) are added automatically
    {
      name = "$pack_name-governance-import";
      check = '''
        echo "[✓] Governance file $governance_file imported successfully"
      ''';
    }
  ];
}
EOF
  }

  show_completion_report() {
    local parameterized_packs="$1"
    local direct_packs="$2"
    local all_pack_names="$3"

    local created_count=0
    local pack_list=""

    # Count created packs and build list
    for pack_file in packs/*/*.nix; do
      if [[ -f "$pack_file" ]]; then
        pack_name=$(basename "$pack_file" .nix)
        category=$(basename "$(dirname "$pack_file")")
        created_count=$((created_count + 1))
        pack_list="$pack_list  ├── $category/$pack_name.nix\n"
      fi
    done

    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                  Import Complete                           ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    if [[ -n "$parameterized_packs" ]]; then
      echo "Parameterized packs to enable in .nixline.toml:"
      echo "  $parameterized_packs"
      echo ""
    fi

    if [[ -n "$direct_packs" ]]; then
      echo "Direct content packs created:"
      echo "  $direct_packs"
      echo ""
    fi

    if [[ $created_count -gt 0 ]]; then
      echo "Generated pack files:"
      echo "  packs/"
      echo -e "$pack_list"
      echo ""
    fi

    echo "Recommended .nixline.toml configuration:"
    echo "[packs]"
    echo "enabled = [$(echo "$all_pack_names" | sed 's/ /", "/g' | sed 's/^/"/' | sed 's/$/"/')]"
    echo ""

    echo "Next steps:"
    echo "  1. Copy the recommended configuration to .nixline.toml"
    echo "  2. Customize parameterized pack settings as needed"
    echo "  3. Test with 'nix run .#sync' to materialize files"
    echo "  4. Validate with 'nix run .#check'"
    echo ""
  }

  validate_pack_input() {
    local pack_name="$1"
    local category
    category=$(get_pack_category "$pack_name" "")
    local pack_file="packs/$category/$pack_name.nix"

    echo ""
    echo "Running input validation for $pack_name..."

    # Check if pack file exists
    if [[ ! -f "$pack_file" ]]; then
      echo "Error: Pack file $pack_file not found" >&2
      exit 1
    fi

    local validation_issues=0

    # 1. Check for dangerous network operations
    if grep -q "fetchurl\|fetchGit\|fetchTarball" "$pack_file"; then
      echo "WARNING: Pack contains network fetch operations"
      echo "   Review network access patterns for security"
      validation_issues=$((validation_issues + 1))
    fi

    # 2. Check for command execution
    if grep -q "runCommand\|writeShellScript\|system\|exec" "$pack_file"; then
      echo "WARNING: Pack contains command execution"
      echo "   Ensure commands are safe and don't use untrusted input"
      validation_issues=$((validation_issues + 1))
    fi

    # 3. Check for environment variable usage
    if grep -q "getEnv\|env\." "$pack_file"; then
      echo "WARNING: Pack uses environment variables"
      echo "   Validate that environment access is safe"
      validation_issues=$((validation_issues + 1))
    fi

    # 4. Check for file system operations beyond normal pack behavior
    if grep -q "readFile\|writeFile\|copyFile" "$pack_file"; then
      echo "INFO: Pack performs file operations"
      echo "   Verify file access is limited to intended policy files"
    fi

    # 5. Check for dangerous string interpolation patterns
    if grep -E '\$\{[^}]*\$\{|\$\([^)]*\$\(' "$pack_file"; then
      echo "WARNING: Pack contains nested string interpolation"
      echo "   Review for potential injection vulnerabilities"
      validation_issues=$((validation_issues + 1))
    fi

    # 6. Check for hardcoded secrets patterns
    if grep -iE '(password|secret|key|token|credential).*[=:]\s*"[^"]{8,}"' "$pack_file"; then
      echo "ERROR: Pack appears to contain hardcoded secrets"
      echo "   Remove any hardcoded credentials immediately"
      validation_issues=$((validation_issues + 10))
    fi

    # 7. Validate Nix syntax
    if ! nix-instantiate --parse "$pack_file" >/dev/null 2>&1; then
      echo "ERROR: Pack contains invalid Nix syntax"
      echo "   Fix syntax errors before using this pack"
      validation_issues=$((validation_issues + 5))
    fi

    # Report results
    echo ""
    if [[ $validation_issues -eq 0 ]]; then
      echo "[PASS] Input validation passed - pack appears safe"
    elif [[ $validation_issues -lt 5 ]]; then
      echo "[WARN] Input validation completed with warnings"
      echo "   Review the warnings above before using this pack"
    else
      echo "[FAIL] Input validation failed - critical issues found"
      echo "   Fix critical issues before using this pack"
      exit 1
    fi

    echo ""
    echo "Input validation completed for $pack_name"
    echo "Remember to review pack content manually for organization-specific policies"
  }

  # Main execution
  main "$@"
  '';
}