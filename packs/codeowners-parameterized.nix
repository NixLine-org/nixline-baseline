{ pkgs, lib, config ? {} }:

#
# CODEOWNERS PACK (PARAMETERIZED)
#
# This pack materializes a .github/CODEOWNERS file that defines code review ownership.
# When enabled, all repositories receive this CODEOWNERS file.
#
# CONFIGURATION:
# This pack can be customized via .nixline.toml configuration:
#
# [organization]
# name = "MyCompany"
# default_team = "@MyCompany/maintainers"
#
# [packs.codeowners]
# rules = [
#   { pattern = "*", owners = ["@MyCompany/maintainers"] },
#   { pattern = "*.py", owners = ["@MyCompany/python-team"] }
# ]
# custom_file = "path/to/custom-codeowners.txt"  # Use custom CODEOWNERS file
#
# ENVIRONMENT VARIABLES:
# Can also be customized via environment variables from enhanced sync app:
# - NIXLINE_ORG_NAME: Organization name
# - NIXLINE_ORG_TEAM: Default team
#
# See: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
#

let
  # Organization configuration with fallbacks
  orgName =
    if builtins.getEnv "NIXLINE_ORG_NAME" != "" then builtins.getEnv "NIXLINE_ORG_NAME"
    else config.organization.name or "NixLine-org";

  defaultTeam =
    if builtins.getEnv "NIXLINE_ORG_TEAM" != "" then builtins.getEnv "NIXLINE_ORG_TEAM"
    else config.organization.default_team or "@${orgName}/maintainers";

  # Pack-specific configuration with defaults
  packConfig = config.packs.codeowners or {};
  customFile = packConfig.custom_file or null;

  # Default ownership rules
  defaultRules = [
    { pattern = "*"; owners = [ defaultTeam ]; comment = "Default owners for everything"; }
    { pattern = "*.nix"; owners = [ "@${orgName}/nix-team" ]; comment = "Nix files"; }
    { pattern = "flake.lock"; owners = [ "@${orgName}/nix-team" ]; comment = null; }
    { pattern = ".github/workflows/**"; owners = [ "@${orgName}/devops" ]; comment = "CI/CD workflows"; }
    { pattern = "*.md"; owners = [ "@${orgName}/docs" ]; comment = "Documentation"; }
  ];

  # Use configured rules or defaults
  rules = packConfig.rules or defaultRules;

  # Ensure owner has @ prefix if it doesn't start with @
  normalizeOwner = owner:
    if lib.hasPrefix "@" owner then owner
    else "@${owner}";

  # Generate CODEOWNERS file from rules
  formatRule = rule:
    let
      commentLine = if (rule.comment or null) != null then "# ${rule.comment}\n" else "";
      owners = if builtins.isList rule.owners then rule.owners else [rule.owners];
      normalizedOwners = map normalizeOwner owners;
      ownersStr = lib.concatStringsSep " " normalizedOwners;
    in
    "${commentLine}${rule.pattern} ${ownersStr}";

  # Generate content - either from custom file or rules
  codeownersContent =
    if customFile != null then
      if builtins.pathExists customFile then
        builtins.readFile customFile
      else
        throw "Custom CODEOWNERS file ${customFile} does not exist"
    else
      lib.concatStringsSep "\n\n" (map formatRule rules);

in
{
  files = {
    ".github/CODEOWNERS" =
      if customFile != null then
        codeownersContent
      else ''
      # CODEOWNERS - Generated from nixline-baseline
      # Organization: ${orgName}
      # Default Team: ${defaultTeam}
      #
      # This file is auto-generated. To customize:
      # 1. Add a .nixline.toml file to your repository root
      # 2. Define [packs.codeowners] section with custom rules
      # 3. Run: nix run github:NixLine-org/nixline-baseline#sync

      ${codeownersContent}
    '';
  };

  checks = [
    {
      name = "codeowners-syntax";
      check = ''
        if [[ -f .github/CODEOWNERS ]]; then
          echo "Checking CODEOWNERS syntax..."
          # Basic syntax check - ensure all lines have pattern and owners
          while IFS= read -r line; do
            # Skip comments and empty lines
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ "$line" =~ ^[[:space:]]*$ ]] && continue

            # Check that line has at least a pattern and an owner
            if ! echo "$line" | grep -q '@'; then
              echo "Error: CODEOWNERS line missing owner: $line"
              exit 1
            fi
          done < .github/CODEOWNERS
          echo "CODEOWNERS syntax check passed"
        fi
      '';
    }
  ];
}