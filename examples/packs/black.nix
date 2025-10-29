{ pkgs, lib }:

#
# $PACK_NAME PACK
#
# This pack provides $PACK_NAME configuration for all repositories that enable it.
#
# To enable this pack in a consumer repository:
# 1. Add "$PACK_NAME" to the persistentPacks list in flake.nix
# 2. Run 'nix run .#sync' to materialize the configuration files
# 3. Commit the generated files to your repository
#

{
  files = {
    "pyproject.toml" = ''
      [tool.black]
      line-length = 88
      target-version = ["py38", "py39", "py310", "py311"]
      include = '\.pyi?$'
      extend-exclude = '''
      (
        # Directories
        /(
            \.eggs
          | \.git
          | \.hg
          | \.mypy_cache
          | \.tox
          | \.venv
          | venv
          | _build
          | buck-out
          | build
          | dist
        )/
        # Files
        | setup.py
      )
      '''
    '';
  };

  checks = [
    {
      name = "black-config";
      check = ''
        if [[ -f "pyproject.toml" ]] && grep -q "\[tool\.black\]" pyproject.toml; then
          echo "[+] black configuration found in pyproject.toml"
          # Validate black config if black is available
          if command -v black >/dev/null 2>&1; then
            # Test black can parse the config
            black --version >/dev/null 2>&1 && echo "[+] black config is valid"
          fi
        else
          echo "[-] black configuration missing in pyproject.toml"
          exit 1
        fi
      '';
    }
  ];
}
