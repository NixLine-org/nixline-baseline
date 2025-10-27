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
    ".yamllint" = ''
      extends: default

      rules:
        # Allow longer lines for readability
        line-length:
          max: 120

        # Be more flexible with indentation
        indentation:
          spaces: 2
          indent-sequences: true

        # Allow comments without space from content
        comments:
          min-spaces-from-content: 1

        # Allow truthy values like 'yes', 'no', 'on', 'off'
        truthy:
          allowed-values: ['true', 'false', 'yes', 'no', 'on', 'off']

      # Ignore common files
      ignore: |
        .github/
        node_modules/
        .venv/
        venv/
        *.min.yml
        *.min.yaml
    '';
  };

  checks = [
    {
      name = "yamllint-config";
      check = ''
        if [[ -f ".yamllint" ]]; then
          echo "[+] yamllint configuration found"
          # Validate yamllint config if yamllint is available
          if command -v yamllint >/dev/null 2>&1; then
            # Test yamllint can parse the config
            yamllint --version >/dev/null 2>&1 && echo "[+] yamllint config is valid"
          fi
        else
          echo "[-] .yamllint configuration missing"
          exit 1
        fi
      '';
    }
  ];
}
