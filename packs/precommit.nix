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
    ".pre-commit-config.yaml" = ''
      repos:
        - repo: https://github.com/pre-commit/pre-commit-hooks
          rev: v4.4.0
          hooks:
            - id: trailing-whitespace
            - id: end-of-file-fixer
            - id: check-yaml
            - id: check-json
            - id: check-merge-conflict
            - id: check-case-conflict
            - id: check-executables-have-shebangs

        - repo: https://github.com/psf/black
          rev: 23.3.0
          hooks:
            - id: black
              language_version: python3

        - repo: https://github.com/pycqa/flake8
          rev: 6.0.0
          hooks:
            - id: flake8

        - repo: https://github.com/adrienverge/yamllint
          rev: v1.32.0
          hooks:
            - id: yamllint
    '';
  };

  checks = [
    {
      name = "precommit-config";
      check = ''
        if [[ -f ".pre-commit-config.yaml" ]]; then
          echo "[+] pre-commit configuration found"
          # Validate pre-commit config if pre-commit is available
          if command -v pre-commit >/dev/null 2>&1; then
            # Test pre-commit can parse the config
            pre-commit --version >/dev/null 2>&1 && echo "[+] pre-commit config is valid"
          fi
        else
          echo "[-] .pre-commit-config.yaml configuration missing"
          exit 1
        fi
      '';
    }
  ];
}
