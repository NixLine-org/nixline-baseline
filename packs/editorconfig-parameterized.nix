{ pkgs, lib, config ? {} }:

#
# EDITORCONFIG PACK (PARAMETERIZED)
#
# This pack materializes an .editorconfig file for consistent code formatting.
# When enabled, all repositories receive these editor settings.
#
# CONFIGURATION:
# This pack can be customized via .nixline.toml configuration:
#
# [packs.editorconfig]
# indent_size = 4
# line_length = 100
# charset = "utf-8"
# end_of_line = "lf"
# trim_trailing_whitespace = true
# insert_final_newline = true
#
# [packs.editorconfig.languages]
# yaml = { indent_size = 2 }
# python = { indent_size = 4, max_line_length = 88 }
# javascript = { indent_size = 2 }
#
# See: https://editorconfig.org/
#

let
  # Pack-specific configuration with defaults
  packConfig = config.packs.editorconfig or {};

  # Default settings for all files
  defaultSettings = {
    charset = packConfig.charset or "utf-8";
    end_of_line = packConfig.end_of_line or "lf";
    insert_final_newline = if (packConfig.insert_final_newline or true) then "true" else "false";
    trim_trailing_whitespace = if (packConfig.trim_trailing_whitespace or true) then "true" else "false";
    indent_style = packConfig.indent_style or "space";
    indent_size = toString (packConfig.indent_size or 2);
  } // (if packConfig ? line_length then { max_line_length = toString packConfig.line_length; } else {});

  # Language-specific overrides from config
  languageConfig = packConfig.languages or {};

  # Default language-specific settings
  defaultLanguageSettings = [
    {
      pattern = "*.{nix,yml,yaml}";
      settings = {
        indent_style = "space";
        indent_size = toString (languageConfig.yaml.indent_size or 2);
      };
    }
    {
      pattern = "*.md";
      settings = {
        trim_trailing_whitespace = "false";
      } // (if languageConfig.markdown ? indent_size
            then { indent_size = toString languageConfig.markdown.indent_size; }
            else {});
    }
    {
      pattern = "*.py";
      settings = {
        indent_style = "space";
        indent_size = toString (languageConfig.python.indent_size or 4);
      } // (if languageConfig.python ? max_line_length
            then { max_line_length = toString languageConfig.python.max_line_length; }
            else {});
    }
    {
      pattern = "*.{js,jsx,ts,tsx}";
      settings = {
        indent_style = "space";
        indent_size = toString (languageConfig.javascript.indent_size or 2);
      } // (if languageConfig.javascript ? max_line_length
            then { max_line_length = toString languageConfig.javascript.max_line_length; }
            else {});
    }
    {
      pattern = "*.{c,cpp,h,hpp}";
      settings = {
        indent_style = "space";
        indent_size = toString (languageConfig.c.indent_size or 4);
      } // (if languageConfig.c ? max_line_length
            then { max_line_length = toString languageConfig.c.max_line_length; }
            else {});
    }
    {
      pattern = "*.{rs}";
      settings = {
        indent_style = "space";
        indent_size = toString (languageConfig.rust.indent_size or 4);
      } // (if languageConfig.rust ? max_line_length
            then { max_line_length = toString languageConfig.rust.max_line_length; }
            else {});
    }
    {
      pattern = "*.{go}";
      settings = {
        indent_style = "tab";
        tab_width = toString (languageConfig.go.tab_width or 4);
      };
    }
    {
      pattern = "*.{java,kt,scala}";
      settings = {
        indent_style = "space";
        indent_size = toString (languageConfig.java.indent_size or 4);
      } // (if languageConfig.java ? max_line_length
            then { max_line_length = toString languageConfig.java.max_line_length; }
            else {});
    }
    {
      pattern = "Makefile";
      settings = {
        indent_style = "tab";
      };
    }
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

  languageSections = lib.concatStringsSep "\n\n" (map formatLanguageSection defaultLanguageSettings);

in
{
  files = {
    ".editorconfig" = ''
      # EditorConfig - Generated from nixline-baseline
      # This file defines consistent coding styles for this repository
      # See: https://editorconfig.org/

      root = true

      [*]
      ${formatSettings defaultSettings}

      ${languageSections}
    '';
  };

  checks = [
    {
      name = "editorconfig-syntax";
      check = ''
        if [[ -f .editorconfig ]]; then
          echo "Checking .editorconfig syntax..."
          # Basic syntax validation
          if ! grep -q "root = true" .editorconfig; then
            echo "Warning: .editorconfig missing 'root = true' declaration"
          fi

          # Check for required [*] section
          if ! grep -q "\\[\\*\\]" .editorconfig; then
            echo "Error: .editorconfig missing universal [*] section"
            exit 1
          fi

          echo ".editorconfig syntax check passed"
        fi
      '';
    }
  ];
}