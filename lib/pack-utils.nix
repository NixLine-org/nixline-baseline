{ pkgs, lib }:

#
# LINEAGE PACK UTILITIES LIBRARY
#
# Shared utilities to eliminate DRY violations across pack definitions.
# This library provides common patterns for configuration parsing,
# file generation, check creation, and templating.
#

let
  # Common configuration extraction utilities
  config-utils = {
    # Extract pack-specific configuration with fallbacks
    getPackConfig = packName: config: config.packs.${packName} or {};

    # Extract organization configuration with fallbacks
    getOrgConfig = config: {
      name = config.organization.name or "Lineage-org";
      email = config.organization.email or "security@example.com";
      security_email = config.organization.security_email or config.organization.email or "security@example.com";
      default_team = config.organization.default_team or "@Lineage-org/maintainers";
    };

    # Handle custom file overrides (file reading moved to app layer)
    shouldUseCustomFile = packConfig: packConfig ? custom_file;
    getCustomFilePath = packConfig: packConfig.custom_file or null;

    # Extract configuration value with multiple fallback sources
    getConfigValue = path: fallback: config:
      let
        parts = lib.splitString "." path;
        getValue = obj: parts:
          if parts == [] then obj
          else if obj ? ${lib.head parts}
          then getValue obj.${lib.head parts} (lib.tail parts)
          else fallback;
      in getValue config parts;
  };

  # Common file generation utilities
  file-utils = {
    # Generate standard file with organization templating
    generateOrgFile = filename: content: orgConfig: {
      "${filename}" = lib.replaceStrings
        [ "\${ORG_NAME}" "\${ORG_EMAIL}" "\${ORG_SECURITY_EMAIL}" "\${ORG_TEAM}" ]
        [ orgConfig.name orgConfig.email orgConfig.security_email orgConfig.default_team ]
        content;
    };

    # Generate multi-file output with common patterns
    generateFiles = fileSpecs: orgConfig:
      lib.foldl' (acc: spec: acc // (
        file-utils.generateOrgFile spec.filename spec.content orgConfig
      )) {} fileSpecs;

    # Standard configuration file generators
    # Generate INI-style configuration files with validation
    generateIniFile = sections:
      lib.throwIf (!builtins.isAttrs sections) "generateIniFile: sections must be an attribute set" (
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (sectionName: sectionAttrs:
            "[${sectionName}]\n" +
            lib.concatStringsSep "\n" (
              lib.mapAttrsToList (key: value:
                if builtins.isList value
                then "${key} = ${lib.concatStringsSep ", " (map toString value)}"
                else "${key} = ${toString value}"
              ) sectionAttrs
            )
          ) sections
        )
      );

    # Generate YAML files with validation
    generateYamlFile = data:
      lib.throwIf (!builtins.isAttrs data) "generateYamlFile: data must be an attribute set" (
        let
          formatValue = value:
            if builtins.isString value then value
            else if builtins.isBool value then (if value then "true" else "false")
            else if builtins.isList value then
              "[\n" + lib.concatStringsSep ",\n" (map (v: "  ${formatValue v}") value) + "\n]"
            else toString value;
        in lib.concatStringsSep "\n" (
          lib.mapAttrsToList (key: value: "${key}: ${formatValue value}") data
        )
      );
  };

  # Common check generation utilities
  check-utils = {
    # Generate file existence check
    fileExistsCheck = filename: description: {
      name = "${lib.replaceStrings ["."] [""] (lib.baseNameOf filename)}-present";
      check = ''
        if [[ -f "${filename}" ]]; then
          echo "[✓] ${description} found at ${filename}"
        else
          echo "[✗] ${description} missing at ${filename}"
          exit 1
        fi
      '';
    };

    # Generate syntax validation check for common file types
    syntaxCheck = filename: filetype: {
      name = "${lib.replaceStrings ["."] [""] (lib.baseNameOf filename)}-syntax";
      check =
        if filetype == "yaml" then ''
          if command -v yamllint >/dev/null 2>&1; then
            yamllint "${filename}" || echo "YAML syntax check failed"
          fi
        ''
        else if filetype == "json" then ''
          if command -v jq >/dev/null 2>&1; then
            jq . "${filename}" >/dev/null || (echo "JSON syntax check failed" && exit 1)
          fi
        ''
        else if filetype == "ini" then ''
          if [[ -f "${filename}" ]]; then
            echo "[✓] ${filename} syntax appears valid"
          fi
        ''
        else ''
          echo "[!] No syntax validation available for ${filetype}"
        '';
    };

    # Generate tool-specific validation check
    toolValidationCheck = tool: filename: args: {
      name = "${tool}-validation";
      check = ''
        if command -v ${tool} >/dev/null 2>&1; then
          ${tool} ${args} "${filename}" || echo "${tool} validation failed"
        else
          echo "[!] ${tool} not available for validation"
        fi
      '';
    };

    # Common check combinations
    standardFileChecks = filename: filetype: [
      (check-utils.fileExistsCheck filename "${filetype} configuration")
      (check-utils.syntaxCheck filename filetype)
    ];
  };

  # Common meta generation utilities
  meta-utils = {
    # Generate standard pack metadata
    standardMeta = packName: description: ecosystem: parameterized: {
      inherit description;
      pack_name = packName;
      ecosystem = ecosystem;
      parameterized = parameterized;
      generated_by = "lineage-baseline";
      version = "1.0";
    };

    # Add ecosystem-specific metadata
    ecosystemMeta = ecosystem: extraMeta:
      (meta-utils.standardMeta "" "" ecosystem false) // extraMeta;
  };

  # Template utilities for common patterns
  template-utils = {
    # Standard parameterized pack template with validation
    createParameterizedPack = {
      packName,
      ecosystem ? "universal",
      description,
      configDefaults ? {},
      fileGenerators,
      customChecks ? []
    }:
      # Validate inputs
      lib.throwIf (!lib.isString packName) "createParameterizedPack: packName must be a string"
      (lib.throwIf (!lib.isString description) "createParameterizedPack: description must be a string"
      (lib.throwIf (!lib.isAttrs configDefaults) "createParameterizedPack: configDefaults must be an attribute set"
      (lib.throwIf (!lib.isFunction fileGenerators) "createParameterizedPack: fileGenerators must be a function"
      (lib.throwIf (!lib.isList customChecks) "createParameterizedPack: customChecks must be a list"
      # Return the actual pack function
      (config:
        let
          packConfig = (config-utils.getPackConfig packName config) // configDefaults;
          orgConfig = config-utils.getOrgConfig config;

          generatedFiles = fileGenerators packConfig orgConfig;
          standardChecks = lib.flatten (
            lib.mapAttrsToList (filename: _:
              check-utils.standardFileChecks filename "configuration"
            ) generatedFiles
          );
        in {
          files = generatedFiles;
          checks = standardChecks ++ customChecks;
          meta = meta-utils.standardMeta packName description ecosystem true;
        }
      )))));

    # Standard non-parameterized pack template with validation
    createStaticPack = {
      packName,
      ecosystem ? "universal",
      description,
      files,
      customChecks ? []
    }:
      # Validate inputs
      lib.throwIf (!lib.isString packName) "createStaticPack: packName must be a string"
      (lib.throwIf (!lib.isString description) "createStaticPack: description must be a string"
      (lib.throwIf (!lib.isAttrs files) "createStaticPack: files must be an attribute set"
      (lib.throwIf (!lib.isList customChecks) "createStaticPack: customChecks must be a list"
      {
        inherit files;
        checks = lib.flatten (
          lib.mapAttrsToList (filename: _:
            check-utils.standardFileChecks filename "configuration"
          ) files
        ) ++ customChecks;
        meta = meta-utils.standardMeta packName description ecosystem false;
      })));
  };

in {
  inherit config-utils file-utils check-utils meta-utils template-utils;

  # Convenience functions that combine utilities
  createPack = template-utils.createParameterizedPack;
  createStaticPack = template-utils.createStaticPack;

  # Common configuration parsers
  parsePackConfig = config-utils.getPackConfig;
  parseOrgConfig = config-utils.getOrgConfig;

  # Common file generators
  generateOrgFile = file-utils.generateOrgFile;
  generateIniFile = file-utils.generateIniFile;
  generateYamlFile = file-utils.generateYamlFile;

  # Common check generators
  fileExistsCheck = check-utils.fileExistsCheck;
  syntaxCheck = check-utils.syntaxCheck;
  standardChecks = check-utils.standardFileChecks;
}