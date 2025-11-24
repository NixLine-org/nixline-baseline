{ pkgs, lib, config ? {} }:

#
# YAMLLINT PACK (Parameterized)
#
# YAML linting configuration for consistent YAML file formatting.
# Enforces style rules for readability and prevents common YAML syntax errors.
#

let
  cfg = config.yamllint or {};

  # Default rules
  lineLength = cfg.line_length or 80;
  indentSpaces = cfg.indent_spaces or 2;
  checkMultiLineStrings = cfg.check_multi_line_strings or false;
  allowDuplicateKeys = cfg.allow_duplicate_keys or false;

  yamllintConfig = ''
    ---
    # yamllint configuration
    # https://yamllint.readthedocs.io/en/stable/configuration.html

    extends: default

    rules:
      line-length:
        max: ${toString lineLength}
        level: warning

      indentation:
        spaces: ${toString indentSpaces}
        indent-sequences: true
        check-multi-line-strings: ${lib.boolToString checkMultiLineStrings}

      key-duplicates:
        forbid-duplicated-merge-keys: ${lib.boolToString (!allowDuplicateKeys)}

      truthy:
        allowed-values: ['true', 'false']
        check-keys: false

      comments:
        min-spaces-from-content: 1

      brackets:
        min-spaces-inside: 0
        max-spaces-inside: 1

      braces:
        min-spaces-inside: 0
        max-spaces-inside: 1
  '';

in
{
  files = {
    ".yamllint" = yamllintConfig;
  };

  checks = [
    {
      name = "yamllint-config-present";
      check = ''
        if [[ -f ".yamllint" ]]; then
          echo "[+] .yamllint found"
        else
          echo "[-] .yamllint missing"
          exit 1
        fi
      '';
    }
    {
      name = "yamllint-syntax-valid";
      check = ''
        if command -v yamllint >/dev/null 2>&1; then
          if yamllint --version >/dev/null 2>&1; then
            echo "[+] yamllint is available and working"
          else
            echo "[!] yamllint available but may have issues"
          fi
        else
          echo "[!] yamllint not available (install: pip install yamllint)"
        fi
      '';
    }
  ];

  meta = {
    description = "YAML linting configuration with customizable rules";
    homepage = "https://yamllint.readthedocs.io/";
    example = ''
      # Configuration in .lineage.toml:
      [packs.yamllint]
      line_length = 120
      indent_spaces = 4
      check_multi_line_strings = true
    '';
  };
}