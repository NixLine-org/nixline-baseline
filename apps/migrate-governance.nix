{ pkgs, lib }:

/*
  Migrates an existing governance repository to create a custom NixLine baseline.

  This app combines extract-config and import-policy to provide a complete
  migration workflow for organizations wanting to adopt NixLine.

  Usage:
    Direct Consumption:
      nix run github:ORG/nixline-baseline#migrate-governance -- --governance-repo /path/to/repo
      nix run github:ORG/nixline-baseline#migrate-governance -- --help

    Template-Based Consumption:
      nix run .#migrate-governance -- --governance-repo /path/to/repo

  The app will:
  1. Analyze the governance repository for languages and existing configs
  2. Generate appropriate .nixline.toml configuration
  3. Import supported governance files as NixLine packs
  4. Create a complete baseline directory structure
  5. Generate a migration report

  Perfect for CI/CD workflows to automate baseline creation.
*/

pkgs.writeShellApplication {
  name = "nixline-migrate-governance";

  runtimeInputs = with pkgs; [
    coreutils
    findutils
    git
    nix
  ];

  text = ''
    set -euo pipefail

    # Configuration defaults
    GOVERNANCE_REPO=""
    OUTPUT_DIR="./migrated-baseline"
    ORG_NAME="CHANGEME"
    ORG_EMAIL="admin@example.com"
    SECURITY_EMAIL=""
    DEFAULT_TEAM="@CHANGEME/maintainers"
    BASELINE_REF="github:NixLine-org/nixline-baseline"
    VERBOSE=false
    DRY_RUN=false

    show_usage() {
      cat << 'EOF'
╔════════════════════════════════════════════════════════════╗
║              NixLine Governance Migration                  ║
╚════════════════════════════════════════════════════════════╝

Migrate existing governance repositories to NixLine baseline format.

Usage:
  nixline-migrate-governance --governance-repo <url|path> [options]

Required:
  --governance-repo URL     URL or path to existing governance repository
                           (e.g., https://github.com/cisagov/lineage)

Options:
  --output-dir DIR          Output directory (default: ./migrated-baseline)
  --org-name NAME           Organization name (default: CHANGEME)
  --org-email EMAIL         Organization email (default: admin@example.com)
  --security-email EMAIL    Security contact (default: same as org-email)
  --default-team TEAM       Default team handle (default: @CHANGEME/maintainers)
  --baseline-ref REF        NixLine baseline reference (default: github:NixLine-org/nixline-baseline)
  --verbose                 Enable verbose output
  --dry-run                 Show what would be done without making changes
  --help                    Show this help

Examples:
  # Migrate CISAGOV lineage repository from GitHub
  nixline-migrate-governance \
    --governance-repo https://github.com/cisagov/lineage \
    --org-name "CISA" \
    --org-email "vulnerability@cisa.dhs.gov" \
    --output-dir ./cisa-baseline

  # Migrate from local governance repository
  nixline-migrate-governance \
    --governance-repo ./local-governance \
    --org-name "Example Corp" \
    --org-email "admin@example.com" \
    --security-email "security@example.com"

Output:
  Creates a complete NixLine baseline in the output directory with:
  - Imported governance packs
  - Generated .nixline.toml configuration
  - Migration report
  - Ready-to-deploy baseline structure
EOF
    }

    log_info() {
      echo "[INFO] $1"
    }

    log_verbose() {
      if [[ "$VERBOSE" == true ]]; then
        echo "[VERBOSE] $1"
      fi
    }

    log_success() {
      echo "[SUCCESS] $1"
    }

    log_error() {
      echo "[ERROR] $1" >&2
    }

    # Parse arguments
    while [[ $# -gt 0 ]]; do
      case $1 in
        --governance-repo)
          GOVERNANCE_REPO="$2"
          shift 2
          ;;
        --output-dir)
          OUTPUT_DIR="$2"
          shift 2
          ;;
        --org-name)
          ORG_NAME="$2"
          shift 2
          ;;
        --org-email)
          ORG_EMAIL="$2"
          shift 2
          ;;
        --security-email)
          SECURITY_EMAIL="$2"
          shift 2
          ;;
        --default-team)
          DEFAULT_TEAM="$2"
          shift 2
          ;;
        --baseline-ref)
          BASELINE_REF="$2"
          shift 2
          ;;
        --verbose)
          VERBOSE=true
          shift
          ;;
        --dry-run)
          DRY_RUN=true
          shift
          ;;
        --help|-h)
          show_usage
          exit 0
          ;;
        *)
          echo "Unknown option: $1" >&2
          show_usage
          exit 1
          ;;
      esac
    done

    # Utility function to check if input is a URL
    is_url() {
      local input="$1"
      [[ "$input" =~ ^https?:// ]] || [[ "$input" =~ ^git@ ]] || [[ "$input" =~ ^github: ]]
    }

    # Input validation
    validate_inputs() {
      local errors=()

      # Required arguments
      if [[ -z "$GOVERNANCE_REPO" ]]; then
        errors+=("Missing required argument: --governance-repo")
      fi

      # Validate governance repository (URL or local path)
      if [[ -n "$GOVERNANCE_REPO" ]]; then
        if is_url "$GOVERNANCE_REPO"; then
          log_verbose "Governance repository is URL: $GOVERNANCE_REPO"
        elif [[ ! -d "$GOVERNANCE_REPO" ]]; then
          errors+=("Local governance repository not found: $GOVERNANCE_REPO")
        fi
      fi

      # Organization name validation
      if [[ -z "$ORG_NAME" || "$ORG_NAME" == "CHANGEME" ]]; then
        errors+=("Organization name must be specified and cannot be 'CHANGEME'")
      fi

      # Email validation (basic format check)
      if [[ ! "$ORG_EMAIL" =~ ^[^@]+@[^@]+\.[^@]+$ ]]; then
        errors+=("Invalid organization email format: $ORG_EMAIL")
      fi

      # Security email validation if provided
      if [[ -n "$SECURITY_EMAIL" && ! "$SECURITY_EMAIL" =~ ^[^@]+@[^@]+\.[^@]+$ ]]; then
        errors+=("Invalid security email format: $SECURITY_EMAIL")
      fi

      # Output directory validation
      if [[ ! "$DRY_RUN" == true ]]; then
        local output_parent
        output_parent=$(dirname "$OUTPUT_DIR")
        if [[ ! -w "$output_parent" ]]; then
          errors+=("Cannot write to output directory parent: $output_parent")
        fi
      fi

      # Team format validation (should start with @)
      if [[ -n "$DEFAULT_TEAM" && ! "$DEFAULT_TEAM" =~ ^@[^/]+/.+ ]]; then
        log_verbose "Warning: Team handle should follow format @org/team: $DEFAULT_TEAM"
      fi

      if [[ ''${#errors[@]} -gt 0 ]]; then
        log_error "Validation failed:"
        printf '  %s\n' "''${errors[@]}"
        show_usage
        exit 1
      fi
    }

    validate_inputs

    # Set security email default after validation
    if [[ -z "$SECURITY_EMAIL" ]]; then
      SECURITY_EMAIL="$ORG_EMAIL"
    fi

    log_info "Starting governance migration..."
    log_verbose "Governance repo: $GOVERNANCE_REPO"
    log_verbose "Output directory: $OUTPUT_DIR"
    log_verbose "Organization: $ORG_NAME"

    if [[ "$DRY_RUN" == true ]]; then
      log_info "DRY RUN MODE - No files will be created"
    fi

    # Create output directory structure
    if [[ "$DRY_RUN" == false ]]; then
      mkdir -p "$OUTPUT_DIR"/{packs,lib,apps,examples,.github/workflows}
      log_verbose "Created baseline directory structure"
    else
      log_info "Would create directory: $OUTPUT_DIR"
    fi

    # Utility functions for file analysis
    is_binary_file() {
      local file="$1"

      # Check if file exists and is readable
      if [[ ! -r "$file" ]]; then
        return 0  # Treat unreadable as binary
      fi

      # Use 'file' command if available, otherwise check for null bytes
      if command -v file >/dev/null 2>&1; then
        file "$file" | grep -q "text" && return 1 || return 0
      else
        # Check for null bytes in first 1024 characters
        if head -c 1024 "$file" 2>/dev/null | grep -q $'\0'; then
          return 0  # Binary
        else
          return 1  # Text
        fi
      fi
    }

    is_valid_json() {
      local file="$1"

      # Check if file is readable
      if [[ ! -r "$file" ]]; then
        return 1
      fi

      # Check if it's binary first
      if is_binary_file "$file"; then
        return 1
      fi

      # Try to parse as JSON (basic check)
      if command -v jq >/dev/null 2>&1; then
        jq empty "$file" >/dev/null 2>&1
      else
        # Fallback: check for basic JSON structure
        grep -q "^[[:space:]]*{" "$file" 2>/dev/null
      fi
    }

    # Fetch governance repository if it's a URL
    fetch_governance_repo() {
      if is_url "$GOVERNANCE_REPO"; then
        log_info "Fetching governance repository from URL..."
        log_verbose "Repository URL: $GOVERNANCE_REPO"

        # Use Nix's fetchGit to get the repository
        local fetched_path
        fetched_path=$(nix eval --raw --impure --expr "
          let
            src = builtins.fetchGit {
              url = \"$GOVERNANCE_REPO\";
            };
          in src
        " 2>/dev/null)

        if [[ -z "$fetched_path" || ! -d "$fetched_path" ]]; then
          log_error "Failed to fetch governance repository: $GOVERNANCE_REPO"
          log_error "Please check the URL and ensure the repository is accessible"
          exit 1
        fi

        # Get commit info for reproducibility
        local commit_info
        commit_info=$(nix eval --raw --expr "
          let
            src = builtins.fetchGit {
              url = \"$GOVERNANCE_REPO\";
            };
          in src.shortRev + \" (\" + src.rev + \")\"
        " 2>/dev/null)

        log_info "Fetched repository at commit: $commit_info"
        log_verbose "Local path: $fetched_path"

        # Update GOVERNANCE_REPO to point to fetched path
        GOVERNANCE_REPO="$fetched_path"
      else
        log_verbose "Using local governance repository: $GOVERNANCE_REPO"
      fi
    }

    # Fetch governance repository from URL or use local path
    log_info "Fetching governance repository..."
    fetch_governance_repo

    log_info "Analyzing governance repository..."
    cd "$GOVERNANCE_REPO"

    # Language detection with error handling
    detected_languages=()
    analysis_warnings=()

    # JavaScript/TypeScript detection
    if [[ -f "package.json" ]]; then
      if is_binary_file "package.json"; then
        analysis_warnings+=("package.json appears to be binary, skipping JavaScript detection")
        log_verbose "Warning: package.json is binary, skipping"
      elif ! is_valid_json "package.json"; then
        analysis_warnings+=("package.json appears malformed, but detecting JavaScript anyway")
        detected_languages+=("javascript")
        log_verbose "Detected: JavaScript/TypeScript (malformed package.json)"
      else
        detected_languages+=("javascript")
        log_verbose "Detected: JavaScript/TypeScript"
      fi
    fi

    # Python detection
    if [[ -f "pyproject.toml" || -f "setup.py" || -f "requirements.txt" ]]; then
      python_files=()
      [[ -f "pyproject.toml" ]] && python_files+=("pyproject.toml")
      [[ -f "setup.py" ]] && python_files+=("setup.py")
      [[ -f "requirements.txt" ]] && python_files+=("requirements.txt")

      detected_languages+=("python")
      log_verbose "Detected: Python ($(IFS=', '; echo "''${python_files[*]}"))"
    fi

    # Rust detection
    if [[ -f "Cargo.toml" ]]; then
      if is_binary_file "Cargo.toml"; then
        analysis_warnings+=("Cargo.toml appears to be binary, skipping Rust detection")
        log_verbose "Warning: Cargo.toml is binary, skipping"
      else
        detected_languages+=("rust")
        log_verbose "Detected: Rust"
      fi
    fi

    # Go detection
    if [[ -f "go.mod" ]]; then
      if is_binary_file "go.mod"; then
        analysis_warnings+=("go.mod appears to be binary, skipping Go detection")
        log_verbose "Warning: go.mod is binary, skipping"
      else
        detected_languages+=("go")
        log_verbose "Detected: Go"
      fi
    fi

    # Governance file detection with error handling
    declare -A governance_files=(
      [".editorconfig"]="editorconfig"
      ["LICENSE"]="license"
      ["SECURITY.md"]="security"
      [".github/CODEOWNERS"]="codeowners"
      [".github/dependabot.yml"]="dependabot"
    )

    found_governance=()
    suggested_packs=()
    skipped_files=()

    for file_path in "''${!governance_files[@]}"; do
      if [[ -f "$file_path" ]]; then
        pack_name="''${governance_files[$file_path]}"

        # Check if file is readable
        if [[ ! -r "$file_path" ]]; then
          skipped_files+=("$file_path (permission denied)")
          analysis_warnings+=("Cannot read $file_path: permission denied")
          log_verbose "Warning: Cannot read $file_path (permission denied)"
          continue
        fi

        # Check if file is binary
        if is_binary_file "$file_path"; then
          skipped_files+=("$file_path (binary file)")
          analysis_warnings+=("Skipping $file_path: appears to be binary")
          log_verbose "Warning: Skipping $file_path (binary file)"
          continue
        fi

        found_governance+=("$file_path")
        suggested_packs+=("$pack_name")
        log_verbose "Found governance file: $file_path -> $pack_name"
      fi
    done

    # Additional config file detection with error handling
    declare -A additional_config_files=(
      [".prettierrc"]="prettier"
      [".eslintrc.json"]="eslint"
      [".eslintrc.js"]="eslint"
      [".bandit.yml"]="bandit"
      [".flake8"]="flake8"
      [".yamllint"]="yamllint"
      [".pre-commit-config.yaml"]="precommit"
    )

    config_packs=()
    found_config_files=()

    for config_file in "''${!additional_config_files[@]}"; do
      if [[ -f "$config_file" ]]; then
        pack_name="''${additional_config_files[$config_file]}"

        # Check if file is readable
        if [[ ! -r "$config_file" ]]; then
          skipped_files+=("$config_file (permission denied)")
          analysis_warnings+=("Cannot read $config_file: permission denied")
          log_verbose "Warning: Cannot read $config_file (permission denied)"
          continue
        fi

        # Check if file is binary
        if is_binary_file "$config_file"; then
          skipped_files+=("$config_file (binary file)")
          analysis_warnings+=("Skipping $config_file: appears to be binary")
          log_verbose "Warning: Skipping $config_file (binary file)"
          continue
        fi

        # Special validation for JSON config files
        if [[ "$config_file" == *.json ]] && ! is_valid_json "$config_file"; then
          analysis_warnings+=("$config_file appears malformed, but including $pack_name pack anyway")
          log_verbose "Warning: $config_file is malformed JSON"
        fi

        config_packs+=("$pack_name")
        found_config_files+=("$config_file")
        log_verbose "Found config file: $config_file -> $pack_name"
      fi
    done

    # Organization script detection with error handling
    script_packs=()
    found_scripts=()

    log_verbose "Analyzing organization scripts..."

    # Check for executable files in root directory
    for script_file in $(find . -maxdepth 1 -type f -executable 2>/dev/null); do
      if [[ -x "$script_file" && -f "$script_file" ]]; then
        # Check if file is readable and not binary
        if [[ ! -r "$script_file" ]]; then
          skipped_files+=("$script_file (permission denied)")
          analysis_warnings+=("Cannot read script $script_file: permission denied")
          log_verbose "Warning: Cannot read script $script_file (permission denied)"
          continue
        fi

        if is_binary_file "$script_file"; then
          skipped_files+=("$script_file (binary executable)")
          log_verbose "Skipping binary executable: $script_file"
          continue
        fi

        script_name=$(basename "$script_file")
        pack_name="script-$script_name"
        script_packs+=("$pack_name")
        found_scripts+=("$script_file")
        log_verbose "Found executable script: $script_file -> $pack_name"
      fi
    done

    # Check for script files by extension
    for ext in sh py pl rb js; do
      for script_file in $(find . -maxdepth 2 -name "*.$ext" -type f 2>/dev/null); do
        if [[ -f "$script_file" ]]; then
          # Skip if already detected as executable
          if printf '%s\n' "''${found_scripts[@]}" | grep -q "^$script_file$"; then
            continue
          fi

          # Check if file is readable and not binary
          if [[ ! -r "$script_file" ]]; then
            skipped_files+=("$script_file (permission denied)")
            analysis_warnings+=("Cannot read script $script_file: permission denied")
            log_verbose "Warning: Cannot read script $script_file (permission denied)"
            continue
          fi

          if is_binary_file "$script_file"; then
            skipped_files+=("$script_file (binary file)")
            log_verbose "Skipping binary file: $script_file"
            continue
          fi

          script_name=$(basename "$script_file" ".$ext")
          pack_name="script-$script_name"
          script_packs+=("$pack_name")
          found_scripts+=("$script_file")
          log_verbose "Found script by extension: $script_file -> $pack_name"
        fi
      done
    done

    # Check for scripts in common directories
    for dir in scripts bin tools; do
      if [[ -d "$dir" ]]; then
        for script_file in $(find "$dir" -type f 2>/dev/null); do
          # Skip if already detected
          if printf '%s\n' "''${found_scripts[@]}" | grep -q "^$script_file$"; then
            continue
          fi

          # Check if file is readable and not binary
          if [[ ! -r "$script_file" ]]; then
            skipped_files+=("$script_file (permission denied)")
            analysis_warnings+=("Cannot read script $script_file: permission denied")
            log_verbose "Warning: Cannot read script $script_file (permission denied)"
            continue
          fi

          if is_binary_file "$script_file"; then
            skipped_files+=("$script_file (binary file)")
            log_verbose "Skipping binary file in $dir: $script_file"
            continue
          fi

          script_name=$(basename "$script_file")
          # Remove common extensions for pack naming
          script_name=$${script_name%.*}
          pack_name="script-$dir-$script_name"
          script_packs+=("$pack_name")
          found_scripts+=("$script_file")
          log_verbose "Found script in $dir/: $script_file -> $pack_name"
        done
      fi
    done

    # Remove duplicates from script packs
    if [[ ''${#script_packs[@]} -gt 0 ]]; then
      mapfile -t script_packs < <(printf '%s\n' "''${script_packs[@]}" | sort -u)
    fi

    # Language-based pack suggestions
    for lang in "''${detected_languages[@]}"; do
      case "$lang" in
        "javascript")
          suggested_packs+=("prettier" "eslint" "editorconfig")
          ;;
        "python")
          suggested_packs+=("bandit" "flake8" "editorconfig")
          ;;
        "rust"|"go")
          suggested_packs+=("editorconfig")
          ;;
      esac
    done

    # Add config-detected packs
    suggested_packs+=("''${config_packs[@]}")

    # Add script-detected packs
    suggested_packs+=("''${script_packs[@]}")

    # Universal packs
    suggested_packs+=("license" "codeowners" "security")

    # Remove duplicates
    mapfile -t unique_packs < <(printf '%s\n' "''${suggested_packs[@]}" | sort -u)

    log_info "Analysis complete:"
    log_info "  Languages: $(IFS=, ; echo "''${detected_languages[*]}")"
    log_info "  Governance files: ''${#found_governance[@]}"
    log_info "  Config files: ''${#config_packs[@]}"
    log_info "  Scripts: ''${#script_packs[@]}"
    log_info "  Suggested packs: $(printf '%s ' "''${unique_packs[@]}")"

    # Report any skipped files or warnings
    if [[ ''${#skipped_files[@]} -gt 0 ]]; then
      log_info "  Skipped files: ''${#skipped_files[@]}"
      if [[ "$VERBOSE" == true ]]; then
        printf '    %s\n' "''${skipped_files[@]}"
      fi
    fi

    if [[ ''${#analysis_warnings[@]} -gt 0 ]]; then
      log_info "Analysis warnings (''${#analysis_warnings[@]}):"
      printf '  %s\n' "''${analysis_warnings[@]}"
    fi

    # Handle empty repository case gracefully
    if [[ ''${#detected_languages[@]} -eq 0 && ''${#found_governance[@]} -eq 0 && ''${#config_packs[@]} -eq 0 ]]; then
      log_info "Note: No languages or configuration files detected"
      log_info "This appears to be an empty repository or contains only unrecognized files"
      log_info "The baseline will be created with universal packs only"
    fi

    # Generate baseline configuration
    log_info "Generating .nixline.toml configuration..."

    if [[ "$DRY_RUN" == false ]]; then
      cat > "$OUTPUT_DIR/.nixline.toml" << EOF
# NixLine Configuration
# Generated by migrate-governance from $GOVERNANCE_REPO
# $(date)

[organization]
name = "$ORG_NAME"
email = "$ORG_EMAIL"
security_email = "$SECURITY_EMAIL"
default_team = "$DEFAULT_TEAM"

[packs]
enabled = [$(printf '"%s",' "''${unique_packs[@]}" | sed 's/,$//')]

# Migration Summary:
# - Source: $GOVERNANCE_REPO
# - Languages detected: $(IFS=, ; echo "''${detected_languages[*]}")
# - Governance files imported: ''${#found_governance[@]}
# - Total packs: ''${#unique_packs[@]}
EOF
      log_success "Generated .nixline.toml"
    else
      log_info "Would generate .nixline.toml with ''${#unique_packs[@]} packs"
    fi

    # Set up baseline infrastructure
    log_info "Setting up baseline infrastructure..."

    if [[ "$DRY_RUN" == false ]]; then
      # Use nix to get the baseline files
      baseline_path=$(nix eval --raw --impure --expr "builtins.fetchGit { url = \"https://github.com/NixLine-org/nixline-baseline\"; }")

      cp "$baseline_path/flake.nix" "$OUTPUT_DIR/"
      cp -r "$baseline_path/lib" "$OUTPUT_DIR/"
      cp -r "$baseline_path/apps" "$OUTPUT_DIR/"

      log_success "Copied NixLine core files"
    else
      log_info "Would copy NixLine core files from $BASELINE_REF"
    fi

    # Import governance files as packs
    log_info "Importing governance files..."

    if [[ ''${#found_governance[@]} -gt 0 ]]; then
      if [[ "$DRY_RUN" == false ]]; then
        # Copy governance files to output directory for import-policy to find
        cd "$GOVERNANCE_REPO"
        for gov_file in "''${found_governance[@]}"; do
          target_dir="$OUTPUT_DIR/$(dirname "$gov_file")"
          mkdir -p "$target_dir"
          cp "$gov_file" "$target_dir/"
          log_verbose "Copied $gov_file for import"
        done

        # Run import-policy from the output directory
        cd "$OUTPUT_DIR"
        if nix run "$BASELINE_REF#import-policy" -- --auto 2>/dev/null; then
          log_success "Imported ''${#found_governance[@]} governance files"
        else
          log_error "Failed to import governance files, but continuing migration"
          log_info "You may need to manually import governance files after migration"
        fi
      else
        log_info "Would import ''${#found_governance[@]} governance files:"
        printf '  %s\n' "''${found_governance[@]}"
      fi
    else
      log_info "No standard governance files found to import"
      log_info "The baseline will still be created with universal packs"
    fi

    # Create additional packs for extra config files
    log_info "Creating additional configuration packs..."

    cd "$GOVERNANCE_REPO"
    additional_configs=()

    # Use the found_config_files from analysis
    for config_file in "''${found_config_files[@]}"; do
      pack_name=$(basename "$config_file" | sed 's/^\.//; s/\..*$//')

      # Skip if pack already exists
      if [[ -f "$OUTPUT_DIR/packs/$pack_name.nix" ]]; then
        log_verbose "Pack $pack_name.nix already exists, skipping"
        continue
      fi

      additional_configs+=("$config_file")

      if [[ "$DRY_RUN" == false ]]; then
        # Double-check file is still readable before creating pack
        if [[ ! -r "$config_file" ]]; then
          log_error "Cannot read $config_file during pack creation, skipping"
          continue
        fi

        # Read file content safely
        if ! config_content=$(cat "$config_file" 2>/dev/null); then
          log_error "Failed to read $config_file content, skipping pack creation"
          continue
        fi

        cat > "$OUTPUT_DIR/packs/$pack_name.nix" << PACK_EOF
{ pkgs, lib }:

#
# Imported configuration pack
#
# Imported from $config_file during governance migration
# Generated by NixLine governance migration
#

{
  files = {
    "$config_file" = '''
$(printf '%s\n' "$config_content" | while IFS= read -r line; do printf '      %s\n' "$line"; done)
    ''';
  };

  checks = [
    {
      name = "$pack_name-present";
      check = '''
        if [[ -f "$config_file" ]]; then
          echo "[✓] $config_file configuration present"
        else
          echo "[✗] $config_file configuration missing"
          exit 1
        fi
      ''';
    }
  ];
}
PACK_EOF
          log_verbose "Created pack: $pack_name.nix"
        fi
    done

    if [[ ''${#additional_configs[@]} -gt 0 ]]; then
      log_success "Created ''${#additional_configs[@]} additional configuration packs"
    fi

    # Create script packs for organization scripts
    log_info "Creating organization script packs..."

    cd "$GOVERNANCE_REPO"
    created_script_packs=()

    # Use the found_scripts array from analysis
    for i in "''${!found_scripts[@]}"; do
      script_file="''${found_scripts[$i]}"
      script_name=$(basename "$script_file")
      pack_name="script-$script_name"

      # Skip if pack already exists
      if [[ -f "$OUTPUT_DIR/packs/$pack_name.nix" ]]; then
        log_verbose "Script pack $pack_name.nix already exists, skipping"
        continue
      fi

      created_script_packs+=("$script_file")

      if [[ "$DRY_RUN" == false ]]; then
        # Double-check file is still readable before creating pack
        if [[ ! -r "$script_file" ]]; then
          log_error "Cannot read script $script_file during pack creation, skipping"
          continue
        fi

        # Read script content safely
        if ! script_content=$(cat "$script_file" 2>/dev/null); then
          log_error "Failed to read script $script_file content, skipping pack creation"
          continue
        fi

        # Determine if script should be executable
        script_executable="false"
        if [[ -x "$script_file" ]]; then
          script_executable="true"
        fi

        # Get relative path for installation
        script_path="$script_file"
        if [[ "$script_path" =~ ^\./ ]]; then
          script_path="''${script_path#./}"
        fi

        cat > "$OUTPUT_DIR/packs/$pack_name.nix" << SCRIPT_PACK_EOF
{ pkgs, lib }:

#
# Organization Script Pack
#
# Imported from $script_file during governance migration
# Generated by NixLine governance migration
#
# This pack provides organization-specific scripts to consumer repositories
#

{
  files = {
    "$script_path" = '''
$(printf '%s\n' "$script_content")
    ''';
  };

  # Set executable permissions if the original script was executable
  permissions = lib.optionalAttrs ($script_executable) {
    "$script_path" = "755";
  };

  checks = [
    {
      name = "$pack_name-present";
      check = '''
        if [[ -f "$script_path" ]]; then
          echo "[✓] Organization script $script_path present"
          if [[ "$script_executable" == "true" && ! -x "$script_path" ]]; then
            echo "[!] Warning: $script_path should be executable"
          fi
        else
          echo "[✗] Organization script $script_path missing"
          exit 1
        fi
      ''';
    }
  ];
}
SCRIPT_PACK_EOF
          log_verbose "Created script pack: $pack_name.nix (executable: $script_executable)"
        fi
    done

    if [[ ''${#created_script_packs[@]} -gt 0 ]]; then
      log_success "Created ''${#created_script_packs[@]} organization script packs"
    fi

    # Generate migration report
    log_info "Generating migration report..."

    if [[ "$DRY_RUN" == false ]]; then
      cat > "$OUTPUT_DIR/MIGRATION_REPORT.md" << EOF
# Governance Migration Report

**Organization:** $ORG_NAME
**Source Repository:** $GOVERNANCE_REPO
**Migration Date:** $(date)
**Migration Tool:** NixLine migrate-governance

## Summary

- **Languages Detected:** $(IFS=, ; echo "''${detected_languages[*]}")
- **Governance Files Found:** ''${#found_governance[@]}
- **Additional Config Files:** ''${#additional_configs[@]}
- **Organization Scripts Found:** ''${#script_packs[@]}
- **Total Packs Generated:** $(find "$OUTPUT_DIR/packs" -name "*.nix" -type f 2>/dev/null | wc -l)

## Generated Packs

$(find "$OUTPUT_DIR/packs" -name "*.nix" -type f -exec basename {} \; 2>/dev/null | sed 's|\.nix$||' | sed 's/^/- /')

## Next Steps

1. **Review Generated Configuration**
   - Examine .nixline.toml for organization settings
   - Customize pack configurations in packs/ directory

2. **Test the Baseline**
   - Create a test consumer repository
   - Run: \`nix run .#sync\` to test pack deployment
   - Run: \`nix run .#check\` to validate configuration

3. **Deploy to Organization**
   - Commit baseline to git repository
   - Tag stable release
   - Update consumer repositories to reference new baseline

4. **Set Up Automation**
   - Add GitHub Actions workflow for automatic sync
   - Configure dependabot for baseline updates

## Generated Files

\`\`\`
$(find "$OUTPUT_DIR" -type f | sed "s|$OUTPUT_DIR/||" | sort)
\`\`\`

---
Generated by NixLine migrate-governance
EOF
      log_success "Generated migration report: MIGRATION_REPORT.md"
    else
      log_info "Would generate migration report"
    fi

    # Final summary
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                 Migration Complete                        ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    if [[ "$DRY_RUN" == false ]]; then
      echo "Custom NixLine baseline created at: $OUTPUT_DIR"
      echo ""
      echo "Generated baseline contains:"
      echo "  - $(find "$OUTPUT_DIR/packs" -name "*.nix" -type f 2>/dev/null | wc -l) governance packs"
      echo "  - Organization configuration (.nixline.toml)"
      echo "  - NixLine core infrastructure (flake.nix, lib/, apps/)"
      echo "  - Migration report (MIGRATION_REPORT.md)"
      echo ""
      echo "Next steps:"
      echo "  1. cd $OUTPUT_DIR"
      echo "  2. Review generated configuration"
      echo "  3. Test with: nix flake check"
      echo "  4. Deploy to your organization"
    else
      echo "DRY RUN complete. Use --verbose to see detailed analysis."
      echo "Remove --dry-run to perform the actual migration."
    fi

    cd - >/dev/null
  '';
}