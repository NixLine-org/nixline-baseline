{ pkgs, lib, config ? {} }:

#
# PRECOMMIT PACK (PARAMETERIZED)
#
# This pack provides pre-commit configuration for all repositories that enable it.
#
# CONFIGURATION:
# This pack can be customized via .nixline.toml configuration:
#
# [packs.precommit]
# hooks = ["trailing-whitespace", "black", "flake8", "prettier"]
# python_version = "3.11"
# black_line_length = 88
# node_version = "18"
# custom_file = "path/to/custom-precommit.yaml"  # Use custom pre-commit config file
#
# To enable this pack in a consumer repository:
# 1. Add "precommit" to the enabled packs list in .nixline.toml
# 2. Run 'nix run github:ORG/nixline-baseline#sync' to materialize the configuration files
# 3. Commit the generated .pre-commit-config.yaml file to your repository
#

let
  # Pack-specific configuration with defaults
  packConfig = config.packs.precommit or {};
  customFile = packConfig.custom_file or null;

  # Hook configuration
  enabledHooks = packConfig.hooks or [
    "trailing-whitespace"
    "end-of-file-fixer"
    "check-yaml"
    "check-json"
    "black"
    "flake8"
    "yamllint"
  ];

  # Tool versions and settings
  pythonVersion = packConfig.python_version or "python3";
  blackLineLength = toString (packConfig.black_line_length or 88);
  nodeVersion = packConfig.node_version or "18";

  # Helper function to check if hook is enabled
  hookEnabled = hookName: lib.elem hookName enabledHooks;

  # Generate basic hooks section
  basicHooks = lib.optionals (lib.any hookEnabled [
    "trailing-whitespace" "end-of-file-fixer" "check-yaml"
    "check-json" "check-merge-conflict" "check-case-conflict"
  ]) [
    {
      repo = "https://github.com/pre-commit/pre-commit-hooks";
      rev = "v4.4.0";
      hooks = lib.filter (hook: hook != null && hook != {}) [
        (if hookEnabled "trailing-whitespace" then { id = "trailing-whitespace"; } else null)
        (if hookEnabled "end-of-file-fixer" then { id = "end-of-file-fixer"; } else null)
        (if hookEnabled "check-yaml" then { id = "check-yaml"; } else null)
        (if hookEnabled "check-json" then { id = "check-json"; } else null)
        (if hookEnabled "check-merge-conflict" then { id = "check-merge-conflict"; } else null)
        (if hookEnabled "check-case-conflict" then { id = "check-case-conflict"; } else null)
      ];
    }
  ];

  # Generate Python tools section
  pythonHooks = lib.filter (repo: repo != null && repo != {}) [
    (if hookEnabled "black" then {
      repo = "https://github.com/psf/black";
      rev = "23.3.0";
      hooks = [{
        id = "black";
        language_version = pythonVersion;
        args = ["--line-length=${blackLineLength}"];
      }];
    } else null)
    (if hookEnabled "flake8" then {
      repo = "https://github.com/pycqa/flake8";
      rev = "6.0.0";
      hooks = [{
        id = "flake8";
        args = ["--max-line-length=${blackLineLength}"];
      }];
    } else null)
  ];

  # Generate YAML tools section
  yamlHooks = lib.optionals (hookEnabled "yamllint") [
    {
      repo = "https://github.com/adrienverge/yamllint";
      rev = "v1.32.0";
      hooks = [{ id = "yamllint"; }];
    }
  ];

  # Generate JavaScript/TypeScript tools section
  jsHooks = lib.filter (repo: repo != null && repo != {}) [
    (if hookEnabled "prettier" then {
      repo = "https://github.com/pre-commit/mirrors-prettier";
      rev = "v3.0.0";
      hooks = [{
        id = "prettier";
        types_or = ["javascript" "jsx" "ts" "tsx" "json" "yaml" "markdown"];
      }];
    } else null)
    (if hookEnabled "eslint" then {
      repo = "https://github.com/pre-commit/mirrors-eslint";
      rev = "v8.56.0";
      hooks = [{
        id = "eslint";
        types = ["javascript"];
      }];
    } else null)
  ];

  # Combine all hooks, filtering out empty ones
  allRepos = lib.filter (repo: repo != {} && repo ? hooks && repo.hooks != [])
    (basicHooks ++ pythonHooks ++ yamlHooks ++ jsHooks);

  # Generate YAML content
  generatePreCommitConfig = repos: ''
    repos:
${lib.concatStringsSep "\n" (map (repo: ''
      - repo: ${repo.repo}
        rev: ${repo.rev}
        hooks:
${lib.concatStringsSep "\n" (map (hook: ''
          - id: ${hook.id}${
            lib.optionalString (hook ? language_version) "\n            language_version: ${hook.language_version}"
          }${
            lib.optionalString (hook ? args) "\n            args: [${lib.concatStringsSep ", " (map (arg: ''"${arg}"'') hook.args)}]"
          }${
            lib.optionalString (hook ? types) "\n            types: [${lib.concatStringsSep ", " (map (t: ''"${t}"'') hook.types)}]"
          }${
            lib.optionalString (hook ? types_or) "\n            types_or: [${lib.concatStringsSep ", " (map (t: ''"${t}"'') hook.types_or)}]"
          }'') repo.hooks)}
'') repos)}
  '';

  # Generate content - either from custom file or generated config
  precommitContent =
    if customFile != null then
      if builtins.pathExists customFile then
        builtins.readFile customFile
      else
        throw "Custom pre-commit config file ${customFile} does not exist"
    else
      generatePreCommitConfig allRepos;

in
{
  files = {
    ".pre-commit-config.yaml" = precommitContent;
  };

  checks = [
    {
      name = "precommit-config";
      check = ''
        if [[ -f ".pre-commit-config.yaml" ]]; then
          echo "Checking pre-commit configuration..."

          # Validate YAML syntax
          if command -v yamllint >/dev/null 2>&1; then
            yamllint .pre-commit-config.yaml >/dev/null 2>&1 || {
              echo "Error: .pre-commit-config.yaml has YAML syntax errors"
              exit 1
            }
          fi

          # Validate pre-commit config if pre-commit is available
          if command -v pre-commit >/dev/null 2>&1; then
            pre-commit validate-config .pre-commit-config.yaml >/dev/null 2>&1 || {
              echo "Error: .pre-commit-config.yaml is not a valid pre-commit configuration"
              exit 1
            }
          fi

          echo "Pre-commit configuration check passed"
        else
          echo "Error: .pre-commit-config.yaml configuration missing"
          exit 1
        fi
      '';
    }
  ];
}