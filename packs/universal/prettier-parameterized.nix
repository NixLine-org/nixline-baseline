{ pkgs, lib, config ? {} }:

#
# PRETTIER PACK (Parameterized)
#
# Code formatting configuration for JavaScript, TypeScript, JSON, and more.
# Provides consistent code style across projects with ecosystem-specific settings.
#

let
  utils = import ../../lib/pack-utils.nix { inherit pkgs lib; };
in

utils.template-utils.createParameterizedPack {
  packName = "prettier";
  ecosystem = "universal";
  description = "Prettier code formatting configuration";

  configDefaults = {
    print_width = 80;
    tab_width = 2;
    use_tabs = false;
    semi = true;
    single_quote = false;
    quote_props = "as-needed";
    trailing_comma = "es5";
    bracket_spacing = true;
    arrow_parens = "always";
    end_of_line = "lf";
    additional_ignores = [];
  };

  fileGenerators = packConfig: orgConfig:
    let
      prettierConfig = {
        printWidth = packConfig.print_width;
        tabWidth = packConfig.tab_width;
        useTabs = packConfig.use_tabs;
        semi = packConfig.semi;
        singleQuote = packConfig.single_quote;
        quoteProps = packConfig.quote_props;
        trailingComma = packConfig.trailing_comma;
        bracketSpacing = packConfig.bracket_spacing;
        arrowParens = packConfig.arrow_parens;
        endOfLine = packConfig.end_of_line;
      };

      prettierIgnorePatterns = [
        "# Dependencies"
        "node_modules/"
        ".pnp"
        ".pnp.js"
        ""
        "# Build outputs"
        "build/"
        "dist/"
        ".next/"
        "out/"
        ""
        "# Generated files"
        "coverage/"
        ".nyc_output"
        ""
      ] ++ packConfig.additional_ignores;
    in {
      ".prettierrc" = builtins.toJSON prettierConfig;
      ".prettierignore" = lib.concatStringsSep "\n" prettierIgnorePatterns;
    };

  customChecks = [
    (utils.toolValidationCheck "prettier" ".prettierrc" "--check .")
    {
      name = "prettier-ignore-optional";
      check = ''
        if [[ -f ".prettierignore" ]]; then
          echo "[✓] .prettierignore found"
        else
          echo "[!] .prettierignore missing (recommended but optional)"
        fi
      '';
    }
  ];
} config