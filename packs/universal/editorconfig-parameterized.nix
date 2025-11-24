{ pkgs, lib, config ? {} }:

#
# EDITORCONFIG PACK (PARAMETERIZED)
#
# This pack generates .editorconfig files with sensible defaults
# based on widely-adopted community standards.
#
# CONFIGURATION:
# This pack can be customized via .lineage.toml configuration:
#
# [packs.editorconfig]
# indent_size = 2
# line_length = 120
# charset = "utf-8"
# end_of_line = "lf"
# trim_trailing_whitespace = true
# insert_final_newline = true
# custom_editorconfig_file = "./custom.editorconfig"  # Import custom file
#
# [packs.editorconfig.languages]
# python = { indent_size = 4, max_line_length = 88 }
# javascript = { indent_size = 2 }
#

let
  # Pack-specific configuration with defaults
  packConfig = config.packs.editorconfig or {};

  # General configuration
  indentSize = packConfig.indent_size or 2;
  lineLength = packConfig.line_length or 120;
  charset = packConfig.charset or "utf-8";
  endOfLine = packConfig.end_of_line or "lf";
  trimTrailingWhitespace = packConfig.trim_trailing_whitespace or true;
  insertFinalNewline = packConfig.insert_final_newline or true;
  customEditorConfigFile = packConfig.custom_editorconfig_file or null;

  # Language-specific overrides from config
  languageConfig = packConfig.languages or {};

  # Core EditorConfig settings
  rootSettings = {
    charset = charset;
    end_of_line = endOfLine;
    indent_size = toString indentSize;
    indent_style = "space";
    insert_final_newline = toString insertFinalNewline;
    trim_trailing_whitespace = toString trimTrailingWhitespace;
  } // (if packConfig ? line_length then { max_line_length = toString lineLength; } else {});

  # Authoritative language standards from official style guides
  standardLanguageSettings = {
    # Python: PEP 8 (python.org/dev/peps/pep-0008) + Black formatter defaults
    python = {
      pattern = "[*.py]";
      settings = {
        indent_style = "space";
        indent_size = "4";           # PEP 8 standard
        max_line_length = "88";      # Black default (compromise between 79 and readability)
      };
    };

    # JavaScript: Standard Style (standardjs.com) + Prettier defaults
    javascript = {
      pattern = "[*.{js,jsx}]";
      settings = {
        indent_style = "space";
        indent_size = "2";           # Standard Style convention
      };
    };

    # TypeScript: Microsoft TypeScript style + Prettier defaults
    typescript = {
      pattern = "[*.{ts,tsx}]";
      settings = {
        indent_style = "space";
        indent_size = "2";           # TypeScript handbook recommendation
      };
    };

    # Go: Official Go formatting (golang.org/doc/effective_go.html#formatting)
    go = {
      pattern = "[*.go]";
      settings = {
        indent_style = "tab";        # Go standard - tabs only
        tab_width = "4";             # Visual tab width
      };
    };

    # Rust: rustfmt defaults (doc.rust-lang.org/rustfmt)
    rust = {
      pattern = "[*.rs]";
      settings = {
        indent_style = "space";
        indent_size = "4";           # rustfmt default
        max_line_length = "100";     # rustfmt default
      };
    };

    # YAML: YAML specification + common tooling (yaml.org)
    yaml = {
      pattern = "[*.{yml,yaml}]";
      settings = {
        indent_style = "space";      # YAML requires spaces
        indent_size = "2";           # Most common convention
      };
    };

    # Markdown: CommonMark + GitHub convention
    markdown = {
      pattern = "[*.md]";
      settings = {
        trim_trailing_whitespace = "false";  # Preserves intentional line breaks
        indent_size = "2";                   # List indentation
      };
    };

    # Nix: nixpkgs style guide (github.com/NixOS/nixpkgs/blob/master/.editorconfig)
    nix = {
      pattern = "[*.nix]";
      settings = {
        indent_style = "space";
        indent_size = "2";           # nixpkgs convention
      };
    };
  };

  # Helper: Convert settings attrset to EditorConfig format
  formatSettings = settings:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (key: value: "${key} = ${value}") settings
    );

  # Generate a language section with optional custom overrides
  mkLanguageSection = language: standard: custom:
    let
      # Merge standard with custom overrides (custom takes precedence)
      finalSettings = standard.settings // (lib.mapAttrs (_: toString) custom);
    in
      "${standard.pattern}\n${formatSettings finalSettings}";

  # Generate custom language section for languages not in standards
  mkCustomSection = language: settings:
    let
      pattern = "[*.${language}]";
      stringSettings = lib.mapAttrs (_: toString) settings;
    in
      "${pattern}\n${formatSettings stringSettings}";

  # Create sections for all configured languages
  languageSections =
    # Standard languages with possible custom overrides
    (lib.mapAttrsToList (lang: standard:
      mkLanguageSection lang standard (languageConfig.${lang} or {})
    ) standardLanguageSettings)
    ++
    # Purely custom languages not in standards
    (lib.mapAttrsToList (lang: settings:
      if standardLanguageSettings ? ${lang} then null else mkCustomSection lang settings
    ) languageConfig);

  # Generate final EditorConfig content
  generateEditorConfig =
    if customEditorConfigFile != null then
      # Use custom EditorConfig file if specified
      if builtins.pathExists customEditorConfigFile then
        builtins.readFile customEditorConfigFile
      else
        throw "Custom EditorConfig file ${customEditorConfigFile} does not exist"
    else
      # Generate from standards and configuration
      ''
        # EditorConfig - Generated from nixline-baseline
        # This file defines consistent coding styles for this repository
        # See: https://editorconfig.org/

        root = true

        [*]
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "${k} = ${v}") rootSettings)}

        ${lib.concatStringsSep "\n\n" (lib.filter (s: s != null) languageSections)}
      '';

in
{
  files = {
    ".editorconfig" = generateEditorConfig;
  };

  checks = [
    {
      name = "editorconfig-syntax";
      check = ''
        if [[ -f ".editorconfig" ]]; then
          echo "Checking EditorConfig syntax..."

          # Basic syntax validation
          if ! grep -q "root = true" .editorconfig; then
            echo "Warning: .editorconfig missing 'root = true' directive"
          fi

          # Check for required sections
          if ! grep -q "\\[\\*\\]" .editorconfig; then
            echo "Error: .editorconfig missing [*] section"
            exit 1
          fi

          echo "EditorConfig syntax check passed"
        else
          echo "Error: .editorconfig file missing"
          exit 1
        fi
      '';
    }
  ];
}