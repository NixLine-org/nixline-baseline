{ pkgs, lib }:

/*
  Configuration library for loading and parsing .nixline.toml files.

  This library enables consumers to customize pack behavior without forking
  the baseline by providing a configuration file that overrides defaults.

  Expected .nixline.toml structure:

  [baseline]
  repo = "github:NixLine-org/nixline-baseline"
  ref = "stable"

  [organization]
  name = "MyCompany"
  security_email = "security@mycompany.com"
  default_team = "@MyCompany/maintainers"

  [external_sources]
  "@myorg/security-packs" = { url = "github:myorg/nixline-security-packs", ref = "v1.2.0" }
  "@myorg/language-packs" = { url = "github:myorg/nixline-language-packs", ref = "main" }

  [packs]
  enabled = ["editorconfig", "codeowners", "@myorg/security-packs/custom-security"]

  [packs.codeowners]
  rules = [
    { pattern = "*", owners = ["@MyCompany/maintainers"] },
    { pattern = "*.py", owners = ["@MyCompany/python-team"] }
  ]

  [packs.editorconfig]
  indent_size = 4
  line_length = 100

  [packs.security]
  response_time = "within 24 hours"
  supported_versions = [
    { version = "2.x", supported = true }
  ]
*/

let
  # Default configuration when no .nixline.toml exists
  defaultConfig = {
    baseline = {
      repo = "github:NixLine-org/nixline-baseline";
      ref = "stable";
    };

    organization = {
      name = "NixLine-org";
      security_email = "security@example.com";
      default_team = "@NixLine-org/maintainers";
    };

    packs = {
      enabled = [ "editorconfig" "codeowners" "security" "license" "precommit" "dependabot" ];
    };
  };

  # Parse TOML content using remarshal
  parseToml = content:
    let
      tomlFile = pkgs.writeText "config.toml" content;
      jsonFile = pkgs.runCommand "config.json" {
        buildInputs = [ pkgs.remarshal ];
      } ''
        remarshal -if toml -of json < ${tomlFile} > $out
      '';
    in
      lib.importJSON jsonFile;

  # Load configuration from .nixline.toml file
  loadConfig = configPath:
    if builtins.pathExists configPath
    then
      let
        tomlContent = builtins.readFile configPath;
        parsedConfig = parseToml tomlContent;
      in
        lib.recursiveUpdate defaultConfig parsedConfig
    else
      defaultConfig;

  # Load configuration from current directory
  loadLocalConfig = loadConfig ./.nixline.toml;

  # Get pack list from configuration, respecting CLI overrides
  getPacksFromConfig = config: packsArg: excludeArg:
    let
      configPacks = lib.concatStringsSep "," (config.packs.enabled or (defaultConfig.packs.enabled));
      defaultPacks = "editorconfig,codeowners,security,license,precommit,dependabot";
    in
      if packsArg != ""
      then packsArg  # CLI --packs takes highest priority
      else if excludeArg != ""
      then
        # Apply exclusions to config packs or defaults
        let
          basePacks = if config.packs ? enabled then configPacks else defaultPacks;
          excludeList = lib.splitString "," excludeArg;
          packList = lib.splitString "," basePacks;
          filteredPacks = lib.filter (pack: !(lib.elem pack excludeList)) packList;
        in
          lib.concatStringsSep "," filteredPacks
      else configPacks;  # Use config file

  # Get organization configuration with fallbacks
  getOrgConfig = config: {
    name = config.organization.name or defaultConfig.organization.name;
    security_email = config.organization.security_email or defaultConfig.organization.security_email;
    default_team = config.organization.default_team or defaultConfig.organization.default_team;
  };

  # Get pack-specific configuration
  getPackConfig = config: packName:
    config.packs.${packName} or {};

  # Merge CLI overrides into configuration
  applyCliOverrides = config: overrides:
    let
      # Parse override format: pack.key=value or org.key=value
      parseOverride = override:
        let
          parts = lib.splitString "=" override;
          keyPath = lib.splitString "." (lib.head parts);
          value = lib.concatStringsSep "=" (lib.tail parts);
        in
          { inherit keyPath value; };

      # Apply a single override to config
      applyOverride = cfg: override:
        let
          parsed = parseOverride override;
          # Simple implementation for common cases
          # Note: Full path-based override system could be added in future
        in
          if lib.length parsed.keyPath == 2 && lib.head parsed.keyPath == "org"
          then
            cfg // {
              organization = cfg.organization // {
                ${lib.elemAt parsed.keyPath 1} = parsed.value;
              };
            }
          else cfg;  # Skip complex overrides for now
    in
      lib.foldl' applyOverride config overrides;

  # Get external sources configuration
  getExternalSources = config:
    config.external_sources or {};

  # Parse external pack reference (e.g., "@myorg/security-packs/custom-security")
  parseExternalPackRef = packRef:
    let
      parts = lib.splitString "/" packRef;
    in
      if lib.length parts >= 2 && lib.hasPrefix "@" (lib.head parts)
      then {
        isExternal = true;
        source = lib.concatStringsSep "/" (lib.take 2 parts);
        packName = lib.concatStringsSep "/" (lib.drop 2 parts);
      }
      else {
        isExternal = false;
        source = null;
        packName = packRef;
      };

  # Separate internal and external packs from enabled list
  separatePacksByType = config:
    let
      enabledPacks = config.packs.enabled or [];
      parsed = map parseExternalPackRef enabledPacks;
      internal = lib.filter (p: !p.isExternal) parsed;
      external = lib.filter (p: p.isExternal) parsed;
    in {
      internal = map (p: p.packName) internal;
      external = external;
    };

  # Validate configuration structure
  validateConfig = config:
    let
      errors = []
        ++ (if !(config ? organization) then ["Missing [organization] section"] else [])
        ++ (if !(config ? packs) then ["Missing [packs] section"] else [])
        ++ (if !(config.packs ? enabled) then ["Missing packs.enabled list"] else []);
    in
      if errors == []
      then { valid = true; config = config; }
      else { valid = false; errors = errors; };

in {
  inherit
    defaultConfig
    parseToml
    loadConfig
    loadLocalConfig
    getPacksFromConfig
    getOrgConfig
    getPackConfig
    getExternalSources
    parseExternalPackRef
    separatePacksByType
    applyCliOverrides
    validateConfig;
}