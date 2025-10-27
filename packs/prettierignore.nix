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
    ".prettierignore" = ''
      # Dependencies (shouldn't be formatted)
      node_modules/
      package-lock.json
      yarn.lock
      pnpm-lock.yaml

      # Build outputs (generated files)
      dist/
      build/
      out/
      .next/
      .nuxt/
      coverage/

      # Minified/bundled files (already formatted)
      *.min.js
      *.min.css
      *.bundle.js

      # Generated type definitions
      *.d.ts

      # Documentation that shouldn't be auto-formatted
      CHANGELOG.md
      LICENSE

      # Configuration files with specific formatting
      .env*
      *.lock
    '';
    # TODO: Add more configuration files if needed
    # Example:
    # ".$PACK_NAME" = ''
    #   # $PACK_NAME configuration
    #   # Add your configuration content here
    # '';

    # You can define multiple files:
    # ".$\{PACK_NAME\}rc" = "configuration content";
    # "config/$PACK_NAME.conf" = "more configuration";
  };

  checks = [
    # TODO: Add validation checks (optional)
    # These run when 'nix run .#check' is executed
    # Example:
    # {
    #   name = "$PACK_NAME-syntax";
    #   check = ''
    #     if command -v $PACK_NAME >/dev/null 2>&1; then
    #       $PACK_NAME --check-syntax .$PACK_NAME
    #     fi
    #   '';
    # }
  ];
}
