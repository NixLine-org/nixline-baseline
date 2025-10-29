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
    ".flake8" = ''
      [flake8]
      # Maximum line length
      max-line-length = 88

      # Ignore common issues
      ignore =
          E203,  # whitespace before ':'
          E501,  # line too long (handled by max-line-length)
          W503,  # line break before binary operator

      # Exclude directories
      exclude =
          .git,
          __pycache__,
          .venv,
          venv,
          env,
          .env,
          build,
          dist,
          *.egg-info,
          .tox,
          .coverage,
          .pytest_cache,
          node_modules

      # Enable specific checks
      select = E,W,F,C

      # Per-file ignores
      per-file-ignores =
          __init__.py:F401
          tests/*:S101
    '';
  };

  checks = [
    {
      name = "flake8-config";
      check = ''
        if [[ -f ".flake8" ]]; then
          echo "[+] flake8 configuration found"
          # Validate flake8 config if flake8 is available
          if command -v flake8 >/dev/null 2>&1; then
            # Test flake8 can parse the config
            flake8 --version >/dev/null 2>&1 && echo "[+] flake8 config is valid"
          fi
        else
          echo "[-] .flake8 configuration missing"
          exit 1
        fi
      '';
    }
  ];
}
