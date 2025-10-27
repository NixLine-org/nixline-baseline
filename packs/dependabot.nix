{ pkgs, lib }:

#
# DEPENDABOT PACK
#
# This pack materializes a .github/dependabot.yml file for automated dependency updates.
# When enabled, all repositories receive Dependabot configuration.
#
# HOW TO CUSTOMIZE FOR YOUR ORG:
# 1. Edit the updates list below to add package ecosystems
# 2. Adjust schedule intervals (daily, weekly, monthly)
# 3. Configure commit message prefixes
#
# See: https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file
#

let
  # EDIT THIS: Define your Dependabot update configurations
  updates = [
    {
      package-ecosystem = "github-actions";
      directory = "/";
      schedule = { interval = "weekly"; };
      commit-message = {
        prefix = "ci";
        include = "scope";
      };
    }
    # Add more ecosystems as needed:
    # {
    #   package-ecosystem = "npm";
    #   directory = "/";
    #   schedule = { interval = "weekly"; };
    # }
    # {
    #   package-ecosystem = "pip";
    #   directory = "/";
    #   schedule = { interval = "weekly"; };
    # }
    # {
    #   package-ecosystem = "docker";
    #   directory = "/";
    #   schedule = { interval = "weekly"; };
    # }
  ];

  # Format a single attribute
  formatAttr = indent: k: v:
    if builtins.isAttrs v then
      "${indent}${k}:\n${formatAttrs (indent + "  ") v}"
    else
      "${indent}${k}: ${builtins.toJSON v}";

  # Format an attribute set recursively
  formatAttrs = indent: attrs:
    lib.concatStringsSep "\n" (lib.mapAttrsToList (formatAttr indent) attrs);

  # Format a single update block
  formatUpdate = update:
    "  - " + lib.concatStringsSep "\n    " (
      lib.mapAttrsToList (k: v:
        if builtins.isAttrs v then
          "${k}:\n      ${lib.concatStringsSep "\n      " (lib.mapAttrsToList (k2: v2: "${k2}: ${builtins.toJSON v2}") v)}"
        else
          "${k}: ${builtins.toJSON v}"
      ) update
    );

  updatesYaml = lib.concatStringsSep "\n\n" (map formatUpdate updates);
in

{
  files = {
    ".github/dependabot.yml" = ''
      version: 2

      updates:
      ${updatesYaml}
    '';
  };

  checks = [];
}
