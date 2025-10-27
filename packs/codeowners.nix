{ pkgs, lib }:

#
# CODEOWNERS PACK
#
# This pack materializes a .github/CODEOWNERS file that defines code review ownership.
# When enabled, all repositories receive this CODEOWNERS file.
#
# HOW TO CUSTOMIZE FOR YOUR ORG:
# 1. Edit the variables below to set your GitHub org and team names
# 2. Add/remove ownership rules in the rules list
# 3. Format: { pattern = "file-pattern"; owners = [ "@team1" "@team2" ]; }
#
# See: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
#

let
  # EDIT THIS: Your GitHub organization name
  org = "NixLine-org";

  # EDIT THIS: Define your ownership rules
  # Each rule has a pattern and a list of owner teams
  rules = [
    { pattern = "*"; owners = [ "@${org}/maintainers" ]; comment = "Default owners for everything"; }
    { pattern = "*.nix"; owners = [ "@${org}/nix-team" ]; comment = "Nix files"; }
    { pattern = "flake.lock"; owners = [ "@${org}/nix-team" ]; comment = null; }
    { pattern = ".github/workflows/"; owners = [ "@${org}/devops" ]; comment = "CI/CD workflows"; }
    { pattern = "*.md"; owners = [ "@${org}/docs" ]; comment = "Documentation"; }
  ];

  # Generate CODEOWNERS file from rules
  formatRule = rule:
    let
      commentLine = if rule.comment != null then "# ${rule.comment}\n" else "";
      ownersStr = lib.concatStringsSep " " rule.owners;
    in
    "${commentLine}${rule.pattern} ${ownersStr}";

  codeownersContent = lib.concatStringsSep "\n\n" (map formatRule rules);
in

{
  files = {
    ".github/CODEOWNERS" = ''
      # CODEOWNERS - Generated from nixline-baseline
      # Edit packs/codeowners.nix in your baseline to customize

      ${codeownersContent}
    '';
  };

  checks = [];
}
