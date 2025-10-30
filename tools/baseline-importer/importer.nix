# NixLine Baseline Importer
#
# Library for importing governance repositories and converting them to NixLine packs.
# Discovers governance files, detects project ecosystems, and generates appropriate
# pack configurations with .nixline.toml integration.

{ pkgs, lib ? pkgs.lib }:

let
  # Selective governance file detection - only key organizational files
  isGovernanceFile = path: filetype:
    let
      filename = builtins.baseNameOf path;
      dirname = builtins.dirOf path;
      isRegularFile = filetype == "regular";

      # Root-level governance files only (no subdirectory traversal except .github)
      isRootLevel = dirname == "." || dirname == "";
      isGitHubDir = lib.hasInfix ".github" path;
      isDocsDir = lib.hasInfix "docs" path && lib.hasInfix (lib.toLower "security") (lib.toLower filename);

      # Specific governance file patterns
      governanceFiles = [
        # Root configuration files
        ".editorconfig" ".gitignore" ".gitattributes"
        ".pre-commit-config.yaml" ".pre-commit-config.yml"
        ".bandit.yml" ".flake8" ".yamllint" ".isort.cfg"
        ".coveragerc" ".dockerignore" ".prettierignore" ".prettierrc"
        ".mdl_config.yaml" ".ansible-lint"
        "pytest.ini" "requirements.txt"

        # Documentation and policies
        "README.md" "LICENSE" "LICENSE.txt" "CONTRIBUTING.md"
        "SECURITY.md" "CODE_OF_CONDUCT.md" "CHANGELOG.md"
        "CODEOWNERS" "SECURITY.md"

        # Build and dependency files
        "Dockerfile" "Makefile" "package.json" "Cargo.toml" "go.mod" "Gemfile"
      ];

      # GitHub-specific files
      gitHubFiles = [
        "dependabot.yml" "dependabot.yaml"
        "CODEOWNERS" "SECURITY.md" "ISSUE_TEMPLATE" "PULL_REQUEST_TEMPLATE"
      ];

      # Check if file matches governance patterns
      isGovernancePattern =
        builtins.elem filename governanceFiles ||
        builtins.elem (builtins.baseNameOf path) governanceFiles ||
        (isGitHubDir && builtins.any (pattern: lib.hasInfix pattern filename) gitHubFiles) ||
        (isDocsDir && lib.hasInfix "security" (lib.toLower filename));

    in
      isRegularFile && (
        (isRootLevel && isGovernancePattern) ||
        (isGitHubDir && isGovernancePattern) ||
        isDocsDir
      );

  # Input validation
  validateGovernanceRepo = repo:
    lib.throwIf (!(builtins.pathExists repo))
      "Governance repository path does not exist: ${toString repo}"
      repo;

  # Generate pack name from filename (clean and robust)
  generatePackName = filename:
    let
      basename = builtins.baseNameOf filename;
      withoutDot = if lib.hasPrefix "." basename
                   then lib.removePrefix "." basename
                   else basename;
      withoutExt = lib.head (lib.splitString "." withoutDot);
      cleaned = lib.toLower (builtins.replaceStrings ["-" "_"] ["" ""] withoutExt);
    in
      if lib.stringLength cleaned > 20
      then lib.substring 0 20 cleaned
      else cleaned;

  # Recursively discover all governance files
  discoverGovernanceFiles = repoPath:
    let
      walkDir = path: prefix:
        let
          entries = builtins.readDir path;
          processEntry = name: type:
            let
              fullPath = "${path}/${name}";
              relativePath = if prefix == "" then name else "${prefix}/${name}";
            in
              if type == "directory" && !lib.hasPrefix "." name && name != "node_modules"
              then walkDir fullPath relativePath
              else if isGovernanceFile relativePath type
              then [{ path = fullPath; relativePath = relativePath; }]
              else [];
        in
          lib.flatten (lib.mapAttrsToList processEntry entries);
    in walkDir repoPath "";

  # Detect project ecosystem from discovered files
  detectEcosystem = files:
    let
      fileNames = map (f: builtins.baseNameOf f.relativePath) files;
      hasFile = name: builtins.elem name fileNames;

      ecosystems = lib.flatten [
        (lib.optional (hasFile "package.json") "nodejs")
        (lib.optional (hasFile "requirements.txt") "python")
        (lib.optional (hasFile "Cargo.toml") "rust")
        (lib.optional (hasFile "go.mod") "golang")
        (lib.optional (hasFile "Gemfile") "ruby")
        (lib.optional (hasFile "Dockerfile") "docker")
        (lib.optional (builtins.any (f: lib.hasSuffix ".nix" f.relativePath) files) "nix")
      ];
    in lib.unique ecosystems;

  # Detect license configuration from file content
  detectLicenseConfig = content:
    let
      licenseType =
        if builtins.match ".*CC0 1.0 Universal.*" content != null then "CC0-1.0"
        else if builtins.match ".*Apache License.*" content != null then "Apache-2.0"
        else if builtins.match ".*MIT License.*" content != null then "MIT"
        else if builtins.match ".*BSD.*Clause.*" content != null then "BSD-3-Clause"
        else if builtins.match ".*GNU GENERAL PUBLIC LICENSE.*Version 3.*" content != null then "GPL-3.0-only"
        else if builtins.match ".*Creative Commons.*" content != null then "CC-BY-4.0"
        else "Apache-2.0";

      # CC0 licenses waive copyright, so no holder/year needed
      isCC0 = licenseType == "CC0-1.0";

      copyrightMatch = builtins.match ".*Copyright ([0-9]+) ([^\n\r]+).*" content;
      year = if isCC0 then null
             else if copyrightMatch != null then builtins.elemAt copyrightMatch 0
             else "2025";
      holder = if isCC0 then null
               else if copyrightMatch != null then builtins.elemAt copyrightMatch 1
               else "CHANGEME";
    in {
      type = licenseType;
    } // lib.optionalAttrs (!isCC0) { inherit year holder; };

  # Map governance files to parameterized packs
  getParameterizedPackMapping = filename:
    let
      basename = builtins.baseNameOf filename;
      mappings = {
        ".pre-commit-config.yaml" = "precommit";
        ".pre-commit-config.yml" = "precommit";
        "LICENSE" = "license";
        "LICENSE.txt" = "license";
        "CODEOWNERS" = "codeowners";
        ".github/CODEOWNERS" = "codeowners";
        "SECURITY.md" = "security";
        ".github/SECURITY.md" = "security";
        ".editorconfig" = "editorconfig";
        ".dependabot.yml" = "dependabot";
        ".github/dependabot.yml" = "dependabot";
        ".gitignore" = "gitignore";
        ".prettierrc" = "prettier";
        ".prettierignore" = "prettier";
        ".yamllint" = "yamllint";
        ".flake8" = "flake8";
        ".eslintrc.js" = "eslint";
        ".eslintrc.json" = "eslint";
        ".eslintrc.yml" = "eslint";
        "jest.config.js" = "jest";
        "jest.config.json" = "jest";
      };
    in mappings.${filename} or mappings.${basename} or null;

  # Enhanced pack generation with ecosystem awareness
  generatePackFromFile = fileInfo: ecosystems: governanceRepoSrc:
    let
      filename = fileInfo.relativePath;
      parameterizedPack = getParameterizedPackMapping filename;

      # If this file maps to a parameterized pack, return the parameterized pack name
      # Otherwise create a direct content pack
    in
      if parameterizedPack != null
      then {
        _isParameterized = true;
        packName = parameterizedPack;
        governanceFile = filename;
        content = builtins.readFile fileInfo.path;
      }
      else
        let
          packName = generatePackName (builtins.baseNameOf filename);
          content = builtins.readFile fileInfo.path;
        in {
          _isParameterized = false;
          pack = { pkgs, lib, config ? {} }: {
            files = {
              "${filename}" = content;
            };

            checks = [
              {
                name = "${packName}-present";
                check = ''
                  if [[ -f "${filename}" ]]; then
                    echo "[+] ${filename} found"
                  else
                    echo "[-] ${filename} missing"
                    exit 1
                  fi
                '';
              }
            ];

            meta = {
              description = "Generated from ${filename}";
              ecosystems = ecosystems;
            };
          };
          packName = packName;
        };

  # Generate ecosystem-aware configurations
  generateEcosystemConfig = ecosystems: packName:
    let
      hasEcosystem = eco: builtins.elem eco ecosystems;

      configs = {
        dependabot = {
          interval = "weekly";
          ecosystems = lib.flatten [
            (lib.optional (hasEcosystem "nodejs") "npm")
            (lib.optional (hasEcosystem "python") "pip")
            (lib.optional (hasEcosystem "rust") "cargo")
            (lib.optional (hasEcosystem "ruby") "bundler")
            "github-actions"
          ];
          assignees = ["@admin"];
        };

        precommit = {
          repos = lib.flatten [
            [{
              repo = "https://github.com/pre-commit/pre-commit-hooks";
              rev = "v4.4.0";
              hooks = ["trailing-whitespace" "end-of-file-fixer" "check-yaml"];
            }]
            (lib.optional (hasEcosystem "python") {
              repo = "https://github.com/psf/black";
              rev = "23.3.0";
              hooks = ["black"];
            })
            (lib.optional (hasEcosystem "nodejs") {
              repo = "https://github.com/pre-commit/mirrors-prettier";
              rev = "v3.0.0";
              hooks = ["prettier"];
            })
          ];
        };

        codeowners = {
          owners = ["@admin"];
          paths = {
            "*" = "@admin";
            "*.nix" = "@nix-team";
            "docs/" = "@docs-team";
          } // lib.optionalAttrs (hasEcosystem "nodejs") {
            "package.json" = "@nodejs-team";
            "*.js" = "@frontend-team";
          } // lib.optionalAttrs (hasEcosystem "python") {
            "requirements*.txt" = "@python-team";
            "*.py" = "@backend-team";
          };
        };

        editorconfig = {
          indent_style = "space";
          indent_size = if hasEcosystem "python" then 4 else 2;
          trim_trailing_whitespace = true;
          insert_final_newline = true;
          charset = "utf-8";
        };
      };

    in configs.${packName} or {};

  # Generate enhanced .nixline.toml with ecosystem awareness
  generateNixlineConfig = packNames: governanceRepoSrc: ecosystems:
    let
      enabledList = lib.concatStringsSep ", " (map (name: ''"${name}"'') packNames);

      # License configuration with detection
      licenseConfig =
        let
          foundFile = lib.findFirst (f: builtins.pathExists "${governanceRepoSrc}/${f}") null ["LICENSE" "LICENSE.txt"];
          content = if foundFile != null then builtins.readFile "${governanceRepoSrc}/${foundFile}" else "";
        in
          if content != "" then detectLicenseConfig content
          else {
            type = "Apache-2.0";
            year = "2025";
            holder = "CHANGEME";
          };

      # All pack configurations
      allPackConfigs = {
        license = licenseConfig;
        codeowners = generateEcosystemConfig ecosystems "codeowners";
        dependabot = generateEcosystemConfig ecosystems "dependabot";
        editorconfig = generateEcosystemConfig ecosystems "editorconfig";
        precommit = generateEcosystemConfig ecosystems "precommit";
        security = {
          contact = "security@example.com";
          policy_url = "https://example.com/security-policy";
        };
      };

      # TOML formatting with proper escaping
      formatValue = key: value:
        if builtins.isString value then ''${key} = "${builtins.replaceStrings [''"''] [''\"''] value}"''
        else if builtins.isBool value then ''${key} = ${lib.boolToString value}''
        else if builtins.isInt value then ''${key} = ${toString value}''
        else if builtins.isList value then
          if builtins.all builtins.isString value
          then ''${key} = [${lib.concatStringsSep ", " (map (s: ''"${s}"'') value)}]''
          else ''${key} = ${builtins.toJSON value}''
        else if builtins.isAttrs value then
          lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v:
            if builtins.isString v then ''${key}.${k} = "${v}"''
            else if builtins.isList v then ''${key}.${k} = [${lib.concatStringsSep ", " (map (s: ''"${s}"'') v)}]''
            else ''${key}.${k} = ${builtins.toJSON v}''
          ) value)
        else ''${key} = ${builtins.toJSON value}'';

      packConfigs = lib.concatStringsSep "\n\n" (lib.mapAttrsToList (packName: config:
        let
          configLines = lib.mapAttrsToList (formatValue) config;
        in ''
[packs.${packName}]
${lib.concatStringsSep "\n" configLines}''
      ) allPackConfigs);

      header = ''
        # NixLine Configuration
        # Generated by NixLine Baseline Importer
        # Detected ecosystems: ${lib.concatStringsSep ", " ecosystems}
      '';

    in ''
${header}

[packs]
enabled = [${enabledList}]

${packConfigs}
  '';

  # Import all governance files from a repository source
  importFromSource = governanceRepoSrc:
    let
      validatedRepo = validateGovernanceRepo governanceRepoSrc;
      discoveredFiles = discoverGovernanceFiles validatedRepo;
      ecosystems = detectEcosystem discoveredFiles;

      # Process each file to determine if it's parameterized or direct
      processedFiles = map (fileInfo:
        generatePackFromFile fileInfo ecosystems validatedRepo
      ) discoveredFiles;

      # Separate parameterized and direct packs
      parameterizedPacks = lib.filter (p: p._isParameterized or false) processedFiles;
      directPacks = lib.filter (p: !(p._isParameterized or false)) processedFiles;

      # Create pack modules for direct packs only
      packModules = lib.listToAttrs (map (packInfo: {
        name = packInfo.packName;
        value = packInfo.pack;
      }) directPacks);

      # Collect all pack names (both parameterized and direct)
      allPackNames = (map (p: p.packName) parameterizedPacks) ++ (map (p: p.packName) directPacks);

    in
      packModules // {
        _meta = {
          discoveredFiles = map (f: f.relativePath) discoveredFiles;
          detectedEcosystems = ecosystems;
          fileCount = builtins.length discoveredFiles;
          parameterizedPacks = map (p: p.packName) parameterizedPacks;
          directPacks = map (p: p.packName) directPacks;
          allPackNames = allPackNames;
        };
      };

  # Import with automatic .nixline.toml generation
  importWithConfig = governanceRepoSrc:
    let
      packs = importFromSource governanceRepoSrc;
      meta = packs._meta;
      actualPacks = builtins.removeAttrs packs ["_meta"];
      directPackNames = builtins.attrNames actualPacks;
      allPackNames = meta.allPackNames or directPackNames;
      ecosystems = meta.detectedEcosystems or [];
      nixlineConfig = generateNixlineConfig allPackNames governanceRepoSrc ecosystems;

      nixlineTomlPack = { pkgs, lib, config ? {} }: {
        files = {
          ".nixline.toml" = nixlineConfig;
        };
        checks = [
          {
            name = "nixline-config-present";
            check = ''
              if [[ -f ".nixline.toml" ]]; then
                echo "[+] .nixline.toml found"
              else
                echo "[-] .nixline.toml missing"
                exit 1
              fi
            '';
          }
        ];
        meta = {
          description = "Generated NixLine configuration";
          inherit ecosystems;
          generatedFrom = meta.discoveredFiles or [];
        };
      };

    in
      actualPacks // {
        nixlineconfig = nixlineTomlPack;
        _meta = meta // {
          configGenerated = true;
          totalPacks = builtins.length allPackNames + 1;
        };
      };

in {
  # Core functions
  inherit isGovernanceFile generatePackName validateGovernanceRepo;
  inherit discoverGovernanceFiles detectEcosystem detectLicenseConfig;
  inherit generateEcosystemConfig generateNixlineConfig;

  # Main import functions
  inherit importFromSource importWithConfig;

  # Legacy compatibility
  generatePackFromFile = filename: governanceRepoSrc:
    generatePackFromFile
      { relativePath = filename; path = "${governanceRepoSrc}/${filename}"; }
      []
      governanceRepoSrc;

  # Utility functions
  utils = {
    validateConfig = config: {
      hasRequiredSections = builtins.all (section:
        lib.hasInfix "[${section}]" config
      ) ["packs"];
      estimatedSize = builtins.stringLength config;
      configSections = lib.filter (line:
        lib.hasPrefix "[" line && lib.hasSuffix "]" line
      ) (lib.splitString "\n" config);
    };
  };
}