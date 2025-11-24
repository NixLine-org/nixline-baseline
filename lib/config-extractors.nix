{ pkgs, lib }:

#
# CONFIGURATION EXTRACTORS LIBRARY
#
# Utilities for extracting configuration from existing files and converting
# them to Lineage pack configuration format. This enables importing existing
# project configurations into parameterized packs.
#

let
  # Common parsing utilities
  parsing-utils = {
    # Parse INI-style configuration files
    parseIniFile = content:
      let
        lines = lib.splitString "\n" content;
        cleanLines = lib.filter (line: line != "" && !lib.hasPrefix "#" line && !lib.hasPrefix ";" line) lines;

        processLine = acc: line:
          if lib.hasPrefix "[" line && lib.hasSuffix "]" line then
            # Section header
            acc // { _currentSection = lib.substring 1 (lib.stringLength line - 2) line; }
          else if lib.hasInfix "=" line then
            # Key-value pair
            let
              parts = lib.splitString "=" line;
              key = lib.trim (lib.head parts);
              value = lib.trim (lib.concatStringsSep "=" (lib.tail parts));
              section = acc._currentSection or "DEFAULT";
            in
              acc // {
                ${section} = (acc.${section} or {}) // { ${key} = value; };
              }
          else acc;
      in
        lib.foldl' processLine {} cleanLines;

    # Parse YAML-style configuration (simplified)
    parseYamlFile = content:
      let
        lines = lib.splitString "\n" content;
        cleanLines = lib.filter (line: line != "" && !lib.hasPrefix "#" line) lines;

        processLine = acc: line:
          if lib.hasInfix ":" line then
            let
              parts = lib.splitString ":" line;
              key = lib.trim (lib.head parts);
              value = lib.trim (lib.concatStringsSep ":" (lib.tail parts));
              cleanKey = lib.replaceStrings [" " "-"] ["_" "_"] key;
            in
              acc // { ${cleanKey} =
                if value == "true" then true
                else if value == "false" then false
                else if lib.match "^[0-9]+$" value != null then lib.toInt value
                else value;
              }
          else acc;
      in
        lib.foldl' processLine {} cleanLines;

    # Parse JSON configuration
    parseJsonFile = content:
      builtins.fromJSON content;

    # Parse simple key=value files
    parseKeyValueFile = content:
      let
        lines = lib.splitString "\n" content;
        cleanLines = lib.filter (line: line != "" && !lib.hasPrefix "#" line) lines;

        processLine = acc: line:
          if lib.hasInfix "=" line then
            let
              parts = lib.splitString "=" line;
              key = lib.trim (lib.head parts);
              value = lib.trim (lib.concatStringsSep "=" (lib.tail parts));
            in
              acc // { ${key} = value; }
          else acc;
      in
        lib.foldl' processLine {} cleanLines;
  };

  # File-specific extractors
  extractors = {
    # Extract EditorConfig settings
    extractEditorConfig = content:
      let
        parsed = parsing-utils.parseIniFile content;
        root = parsed."*" or {};
      in {
        indent_style = root.indent_style or "space";
        indent_size = if root.indent_size != null then lib.toInt root.indent_size else 2;
        end_of_line = root.end_of_line or "lf";
        charset = root.charset or "utf-8";
        trim_trailing_whitespace =
          if root.trim_trailing_whitespace == "true" then true else false;
        insert_final_newline =
          if root.insert_final_newline == "true" then true else false;
        max_line_length =
          if root.max_line_length != null then lib.toInt root.max_line_length else 80;
      };

    # Extract Prettier settings
    extractPrettierConfig = content:
      let
        parsed = parsing-utils.parseJsonFile content;
      in {
        print_width = parsed.printWidth or 80;
        tab_width = parsed.tabWidth or 2;
        use_tabs = parsed.useTabs or false;
        semi = parsed.semi or true;
        single_quote = parsed.singleQuote or false;
        quote_props = parsed.quoteProps or "as-needed";
        trailing_comma = parsed.trailingComma or "es5";
        bracket_spacing = parsed.bracketSpacing or true;
        arrow_parens = parsed.arrowParens or "always";
        end_of_line = parsed.endOfLine or "lf";
      };

    # Extract ESLint settings
    extractEslintConfig = content:
      let
        # Handle both .eslintrc.json and .eslintrc.js formats
        parsed = if lib.hasPrefix "{" content
                 then parsing-utils.parseJsonFile content
                 else {}; # Note: JS format parsing not yet implemented
      in {
        extends = parsed.extends or ["eslint:recommended"];
        env = parsed.env or { browser = true; node = true; };
        parser_options = parsed.parserOptions or { ecmaVersion = 2021; };
        rules = parsed.rules or {};
      };

    # Extract Flake8 settings
    extractFlake8Config = content:
      let
        parsed = parsing-utils.parseIniFile content;
        flake8 = parsed.flake8 or {};
      in {
        max_line_length =
          if flake8.max-line-length != null
          then lib.toInt flake8.max-line-length
          else 88;
        ignore = lib.splitString "," (flake8.ignore or "");
        exclude = lib.splitString "," (flake8.exclude or ".git,__pycache__");
        select = lib.splitString "," (flake8.select or "E,W,F");
      };

    # Extract Yamllint settings
    extractYamllintConfig = content:
      let
        parsed = parsing-utils.parseYamlFile content;
        rules = parsed.rules or {};
      in {
        line_length =
          let lineLength = rules.line_length or {};
          in if lineLength ? max then lineLength.max else 80;
        indentation =
          let indent = rules.indentation or {};
          in if indent ? spaces then indent.spaces else 2;
        document_start =
          let docStart = rules.document_start or "disable";
          in docStart != "disable";
        empty_lines =
          let emptyLines = rules.empty_lines or {};
          in {
            max = emptyLines.max or 2;
            max_start = emptyLines.max-start or 0;
            max_end = emptyLines.max-end or 1;
          };
      };

    # Extract license information
    extractLicenseInfo = content:
      let
        licenseType =
          if lib.hasInfix "Apache License" content then "Apache-2.0"
          else if lib.hasInfix "MIT License" content then "MIT"
          else if lib.hasInfix "BSD" content then "BSD-3-Clause"
          else if lib.hasInfix "GPL" content then "GPL-3.0"
          else "Apache-2.0";

        copyrightMatch = builtins.match ".*Copyright.*([0-9]{4}).*" content;
        year = if copyrightMatch != null then lib.head copyrightMatch else "2025";

        holderMatch = builtins.match ".*Copyright.*[0-9]{4}[^a-zA-Z]*([^\n\r]+).*" content;
        holder = if holderMatch != null then lib.trim (lib.head holderMatch) else "CHANGEME";
      in {
        type = licenseType;
        year = year;
        holder = holder;
      };
  };

  # Main extraction functions
  extractConfig = {
    # Extract configuration from common files
    fromFile = filename: content:
      let
        basename = lib.toLower (builtins.baseNameOf filename);
      in
        if basename == ".editorconfig" then extractors.extractEditorConfig content
        else if basename == ".prettierrc" then extractors.extractPrettierConfig content
        else if lib.hasPrefix ".eslintrc" basename then extractors.extractEslintConfig content
        else if basename == ".flake8" then extractors.extractFlake8Config content
        else if basename == ".yamllint" then extractors.extractYamllintConfig content
        else if basename == "license" || basename == "license.txt" then extractors.extractLicenseInfo content
        else {};

    # Generate TOML configuration section from extracted config
    toTomlSection = packName: extractedConfig:
      let
        formatValue = value:
          if builtins.isString value then ''"${value}"''
          else if builtins.isBool value then (if value then "true" else "false")
          else if builtins.isInt value then toString value
          else if builtins.isList value then ''[${lib.concatStringsSep ", " (map formatValue value)}]''
          else if builtins.isAttrs value then
            "{ " + lib.concatStringsSep ", " (lib.mapAttrsToList (k: v: ''${k} = ${formatValue v}'') value) + " }"
          else toString value;
      in ''
[packs.${packName}]
${lib.concatStringsSep "\n" (lib.mapAttrsToList (key: value:
  "${key} = ${formatValue value}"
) extractedConfig)}
'';

    # Generate example configuration from pack defaults
    generateExample = packName: configDefaults:
      let
        exampleConfig = lib.mapAttrs (key: value:
          if builtins.isString value then "\"custom_${value}\""
          else if builtins.isBool value then (!value)
          else if builtins.isInt value then value + 10
          else value
        ) configDefaults;
      in extractConfig.toTomlSection packName exampleConfig;
  };

in {
  inherit parsing-utils extractors extractConfig;

  # Convenience functions
  extractFromFile = extractConfig.fromFile;
  generateTomlSection = extractConfig.toTomlSection;
  generateExampleConfig = extractConfig.generateExample;

  # Supported file types
  supportedFiles = [
    ".editorconfig"
    ".prettierrc"
    ".eslintrc.json"
    ".eslintrc.js"
    ".flake8"
    ".yamllint"
    "LICENSE"
    "LICENSE.txt"
  ];
}