{ pkgs, lib }:

#
# EDITORCONFIG PACK
#
# This pack materializes an .editorconfig file for consistent code formatting.
# When enabled, all repositories receive these editor settings.
#
# HOW TO CUSTOMIZE FOR YOUR ORG:
# 1. Edit defaultSettings and languageSettings below
# 2. Add patterns for languages your org uses
#
# See: https://editorconfig.org/
#

let
  # EDIT THIS: Default settings for all files
  defaultSettings = {
    charset = "utf-8";
    end_of_line = "lf";  # Use "crlf" for Windows
    insert_final_newline = "true";
    trim_trailing_whitespace = "true";
  };

  # EDIT THIS: Language-specific settings
  # Each entry defines a file pattern and its formatting rules
  languageSettings = [
    {
      pattern = "*.{nix,yml,yaml}";
      settings = {
        indent_style = "space";
        indent_size = "2";
      };
    }
    {
      pattern = "*.md";
      settings = {
        trim_trailing_whitespace = "false";
      };
    }
    # Add more languages as needed:
    # {
    #   pattern = "*.{js,jsx,ts,tsx}";
    #   settings = {
    #     indent_style = "space";
    #     indent_size = "2";
    #   };
    # }
    # {
    #   pattern = "*.py";
    #   settings = {
    #     indent_style = "space";
    #     indent_size = "4";
    #   };
    # }
  ];

  # Helper to format settings
  formatSettings = settings:
    lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "${k} = ${v}") settings);

  # Generate language-specific sections
  formatLanguageSection = lang:
    ''
      [${lang.pattern}]
      ${formatSettings lang.settings}
    '';

  languageSections = lib.concatStringsSep "\n\n" (map formatLanguageSection languageSettings);
in

{
  files = {
    ".editorconfig" = ''
      root = true

      [*]
      ${formatSettings defaultSettings}

      ${languageSections}
    '';
  };

  checks = [];
}
