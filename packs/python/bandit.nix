{ pkgs, lib, config ? {} }:

#
# BANDIT PACK
#
# Python security scanning configuration based on CISA lineage repository.
# Bandit is a tool designed to find common security issues in Python code.
#
# This pack provides the .bandit.yml configuration file with CISA's
# proven security scanning settings for Python projects.
#

let
  utils = import ../../lib/pack-utils.nix { inherit pkgs lib; };
in

utils.template-utils.createStaticPack {
  packName = "bandit";
  ecosystem = "python";
  description = "Python security scanning with Bandit - CISA lineage configuration";

  files = {
    ".bandit.yml" = ''
      ---
      # Configuration file for the Bandit python security scanner
      # https://bandit.readthedocs.io/en/latest/config.html
      # This config is applied to bandit when scanning the "tests" tree

      # Tests are first included by `tests`, and then excluded by `skips`.
      # If `tests` is empty, all tests are considered included.

      tests:
      # - B101
      # - B102

      skips:
        - B101  # skip "assert used" check since assertions are required in pytests
    '';
  };

  customChecks = [
    (utils.toolValidationCheck "bandit" ".bandit.yml" "--help")
    {
      name = "bandit-availability";
      check = ''
        if command -v bandit >/dev/null 2>&1; then
          echo "[✓] Bandit is available"
        else
          echo "[!] Bandit not available (install: pip install bandit)"
        fi
      '';
    }
  ];
}
