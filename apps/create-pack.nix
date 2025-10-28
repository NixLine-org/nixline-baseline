{ pkgs, lib }:

/*
  Creates a new policy pack with a template structure.

  Usage:
    Direct Consumption:
      nix run github:ORG/nixline-baseline#create-pack -- <pack-name>
      nix run github:ORG/nixline-baseline#create-pack -- --list-examples

    Template-Based Consumption:
      nix run .#create-pack -- <pack-name>
      nix run .#create-pack -- --list-examples

  This utility generates a new pack file in packs/ directory with a basic template
  that includes files section and checks section. Users can then customize the
  generated pack to define their organization's policies.

  Examples of pack names: flake8, prettier, jest, dockerfile, etc.
*/

pkgs.writeShellApplication {
  name = "nixline-create-pack";

  runtimeInputs = [ pkgs.coreutils ];

  text = ''
    set -euo pipefail

    show_usage() {
      cat << 'USAGE_EOF'
╔════════════════════════════════════════════════════════════╗
║                NixLine Pack Creator                        ║
╚════════════════════════════════════════════════════════════╝

Create a new policy pack for your NixLine baseline.

Usage:
  nixline-create-pack <pack-name>
  nixline-create-pack --list-examples

Options:
  <pack-name>      Name of the pack to create (e.g., flake8, prettier)
  --list-examples  Show example pack configurations

Examples:
  # Create a flake8 pack
  nixline-create-pack flake8

  # Create a prettier pack
  nixline-create-pack prettier

  # List common pack examples
  nixline-create-pack --list-examples

The pack file will be created in packs/<pack-name>.nix
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
        *)
          PACK_NAME="$1"
          shift
          ;;
      esac
    done

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

    PACK_FILE="packs/$PACK_NAME.nix"

    if [[ -f "$PACK_FILE" ]]; then
      echo "Error: Pack $PACK_NAME already exists at $PACK_FILE" >&2
      exit 1
    fi

    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                Creating NixLine Pack                       ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Pack name: $PACK_NAME"
    echo "File path: $PACK_FILE"
    echo ""

    # Create packs directory if it doesn't exist
    mkdir -p packs

    # Generate pack template
    cat > "$PACK_FILE" << EOF
{ pkgs, lib }:

#
# \$PACK_NAME PACK
#
# This pack provides \$PACK_NAME configuration for all repositories that enable it.
#
# To enable this pack in a consumer repository:
# 1. Add "\$PACK_NAME" to the persistentPacks list in flake.nix
# 2. Run 'nix run .#sync' to materialize the configuration files
# 3. Commit the generated files to your repository
#

{
  files = {
    # TODO: Define configuration files to materialize
    # Example:
    # ".\$PACK_NAME" = '''
    #   # \$PACK_NAME configuration
    #   # Add your configuration content here
    # ''';

    # You can define multiple files:
    # ".\$\{PACK_NAME\}rc" = "configuration content";
    # "config/\$PACK_NAME.conf" = "more configuration";
  };

  checks = [
    # TODO: Add validation checks (optional)
    # These run when 'nix run .#check' is executed
    # Example:
    # {
    #   name = "\$PACK_NAME-syntax";
    #   check = '''
    #     if command -v \$PACK_NAME >/dev/null 2>&1; then
    #       \$PACK_NAME --check-syntax .\$PACK_NAME
    #     fi
    #   ''';
    # }
  ];
}
EOF

    echo "✓ Created $PACK_FILE"
    echo ""
    echo "Next steps:"
    echo "  1. Edit $PACK_FILE to define your configuration files"
    echo "  2. Add \"$PACK_NAME\" to persistentPacks in consumer flake.nix files"
    echo "  3. Run 'nix run .#sync' in consumer repos to materialize the files"
    echo "  4. Test with 'nix run .#check' to validate the configuration"
    echo ""
    echo "Example files you might want to create:"
    echo "  - .$PACK_NAME (main configuration file)"
    echo "  - .\$\{PACK_NAME\}rc (resource configuration)"
    echo "  - config/$PACK_NAME.yml (YAML configuration)"
    echo ""
  '';
}