{ pkgs, lib, config ? {} }:

#
# FLAKE8 PACK (Parameterized)
#
# Python code quality and style checking configuration.
# Enforces PEP8 compliance and detects common Python code issues.
#
# Configuration reference:
# - flake8 documentation: https://flake8.pycqa.org/en/latest/
# - Configuration guide: https://flake8.pycqa.org/en/latest/user/configuration.html
# - Error codes: https://flake8.pycqa.org/en/latest/user/error-codes.html
# - PEP 8 style guide: https://peps.python.org/pep-0008/
#

let
  cfg = config.flake8 or {};

  # Default configuration
  maxLineLength = cfg.max_line_length or 88;  # Compatible with Black formatter
  maxComplexity = cfg.max_complexity or 10;
  selectCodes = cfg.select_codes or "C,D,E,F,W,B,B950";
  ignoreCodes = cfg.ignore_codes or "E501,W503";  # Line length handled by B950, line breaks before binary operators
  exclude = cfg.exclude or [".git" "__pycache__" "build" "dist" ".venv" "venv"];
  enableDocstring = cfg.enable_docstring or true;

  # Build flake8 configuration
  flake8Config = ''
    [flake8]
    max-line-length = ${toString maxLineLength}
    max-complexity = ${toString maxComplexity}
    ${lib.optionalString (selectCodes != "") "select = ${selectCodes}"}
    ${lib.optionalString (ignoreCodes != "") "ignore = ${ignoreCodes}"}
    exclude = ${lib.concatStringsSep "," exclude}

    # Enable specific checks
    ${lib.optionalString enableDocstring ''
    # Documentation style checking
    # D100: Missing docstring in public module
    # D101: Missing docstring in public class
    # D102: Missing docstring in public method
    # D103: Missing docstring in public function
    ''}

    # Complexity and style
    # C901: Function is too complex
    # E: pycodestyle errors
    # F: Pyflakes errors
    # W: pycodestyle warnings
    # B: flake8-bugbear warnings
    # B950: Line too long (more lenient than E501)
  '';

in
{
  files = {
    ".flake8" = flake8Config;
  };

  checks = [
    {
      name = "flake8-config-present";
      check = ''
        if [[ -f ".flake8" ]]; then
          echo "[+] .flake8 found"
        else
          echo "[-] .flake8 missing"
          exit 1
        fi
      '';
    }
    {
      name = "flake8-syntax-valid";
      check = ''
        if command -v flake8 >/dev/null 2>&1; then
          if flake8 --version >/dev/null 2>&1; then
            echo "[+] flake8 is available and working"
          else
            echo "[!] flake8 available but may have issues"
          fi
        else
          echo "[!] flake8 not available (install: pip install flake8)"
        fi
      '';
    }
  ];

  meta = {
    description = "Python code quality checking with flake8";
    homepage = "https://flake8.pycqa.org/";
    example = ''
      # Configuration in .lineage.toml:
      [packs.flake8]
      max_line_length = 100
      max_complexity = 15
      enable_docstring = false
      ignore_codes = "E501,W503,D100"
    '';
  };
}