{ pkgs, lib, config ? {} }:

#
# DEPENDABOT PACK (PARAMETERIZED)
#
# This pack materializes a .github/dependabot.yml file for automated dependency updates.
# When enabled, all repositories receive Dependabot configuration.
#
# CONFIGURATION:
# This pack can be customized via .lineage.toml configuration:
#
# [packs.dependabot]
# schedule = "weekly"  # daily, weekly, monthly
# commit_message_prefix = "deps:"
# ecosystems = ["github-actions", "npm", "pip"]
# reviewers = ["@MyOrg/deps-reviewers"]
# custom_file = "path/to/custom-dependabot.yml"  # Use custom Dependabot file
#
# See: https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file
#

let
  # Pack-specific configuration with defaults
  packConfig = config.packs.dependabot or {};
  customFile = packConfig.custom_file or null;

  # Dependabot configuration
  schedule = packConfig.schedule or "weekly";
  commitMessagePrefix = packConfig.commit_message_prefix or "deps";
  ecosystems = packConfig.ecosystems or ["github-actions"];
  reviewers = packConfig.reviewers or [];

  # Generate update configuration for each ecosystem
  generateUpdate = ecosystem: {
    package-ecosystem = ecosystem;
    directory = "/";
    schedule = { interval = schedule; };
    commit-message = {
      prefix = commitMessagePrefix;
      include = "scope";
    };
  } // (lib.optionalAttrs (reviewers != []) {
    reviewers = reviewers;
  });

  # Generate all updates
  updates = map generateUpdate ecosystems;

  # Format a single attribute
  formatAttr = indent: k: v:
    if builtins.isAttrs v then
      "${indent}${k}:\n${formatAttrs (indent + "  ") v}"
    else if builtins.isList v then
      "${indent}${k}:\n${lib.concatStringsSep "\n" (map (item: "${indent}  - ${builtins.toJSON item}") v)}"
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
        else if builtins.isList v then
          "${k}:\n      ${lib.concatStringsSep "\n      " (map (item: "- ${builtins.toJSON item}") v)}"
        else
          "${k}: ${builtins.toJSON v}"
      ) update
    );

  updatesYaml = lib.concatStringsSep "\n\n" (map formatUpdate updates);

  # Generate content - either from custom file or generated config
  dependabotContent =
    if customFile != null then
      if builtins.pathExists customFile then
        builtins.readFile customFile
      else
        throw "Custom Dependabot file ${customFile} does not exist"
    else
      updatesYaml;

in
{
  files = {
    ".github/dependabot.yml" =
      if customFile != null then
        dependabotContent
      else ''
      # Dependabot configuration - Generated from nixline-baseline
      # To customize, edit .lineage.toml [packs.dependabot] section

      version: 2

      updates:
      ${dependabotContent}
    '';
  };

  checks = [
    {
      name = "dependabot-config";
      check = ''
        if [[ -f ".github/dependabot.yml" ]]; then
          echo "Checking Dependabot configuration..."

          # Validate YAML syntax
          if command -v yamllint >/dev/null 2>&1; then
            yamllint .github/dependabot.yml >/dev/null 2>&1 || {
              echo "Error: .github/dependabot.yml has YAML syntax errors"
              exit 1
            }
          fi

          # Check for required version field
          if ! grep -q "version: 2" .github/dependabot.yml; then
            echo "Error: dependabot.yml missing 'version: 2' field"
            exit 1
          fi

          # Check for updates section
          if ! grep -q "updates:" .github/dependabot.yml; then
            echo "Error: dependabot.yml missing 'updates:' section"
            exit 1
          fi

          echo "Dependabot configuration check passed"
        else
          echo "Error: .github/dependabot.yml configuration missing"
          exit 1
        fi
      '';
    }
  ];
}