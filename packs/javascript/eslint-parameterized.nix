{ pkgs, lib, config ? {} }:

#
# ESLINT PACK (Parameterized)
#
# JavaScript/TypeScript linting configuration with ecosystem-aware rules.
# Provides code quality and style enforcement for JavaScript projects.
#

let
  cfg = config.eslint or {};

  # Default configuration
  extends = cfg.extends or ["eslint:recommended"];
  parser = cfg.parser or null;
  parserOptions = cfg.parser_options or {
    ecmaVersion = "latest";
    sourceType = "module";
  };
  env = cfg.env or {
    browser = true;
    node = true;
    es2021 = true;
  };
  rules = cfg.rules or {
    "no-unused-vars" = "warn";
    "no-console" = "off";
    "semi" = ["error" "always"];
    "quotes" = ["error" "single"];
  };

  # TypeScript-specific configuration
  isTypeScript = cfg.typescript or false;
  tsExtends = if isTypeScript then extends ++ ["@typescript-eslint/recommended"] else extends;
  tsParser = if isTypeScript then "@typescript-eslint/parser" else parser;

  # React-specific configuration
  isReact = cfg.react or false;
  reactExtends = if isReact then tsExtends ++ ["plugin:react/recommended"] else tsExtends;

  # Final configuration
  eslintConfig = {
    extends = reactExtends;
    parser = tsParser;
    parserOptions = parserOptions;
    env = env;
    rules = rules;
  } // lib.optionalAttrs isReact {
    settings = {
      react = {
        version = "detect";
      };
    };
  };

in
{
  files = {
    ".eslintrc.js" = ''
      module.exports = ${builtins.toJSON eslintConfig};
    '';
  };

  checks = [
    {
      name = "eslint-config-present";
      check = ''
        if [[ -f ".eslintrc.js" || -f ".eslintrc.json" || -f ".eslintrc.yml" ]]; then
          echo "[+] ESLint configuration found"
        else
          echo "[-] ESLint configuration missing"
          exit 1
        fi
      '';
    }
    {
      name = "eslint-available";
      check = ''
        if command -v eslint >/dev/null 2>&1; then
          echo "[+] ESLint is available"
        else
          echo "[!] ESLint not available (install: npm install eslint)"
        fi
      '';
    }
  ];

  meta = {
    description = "ESLint configuration for JavaScript/TypeScript projects";
    homepage = "https://eslint.org/";
    example = ''
      # Configuration in .nixline.toml:
      [packs.eslint]
      typescript = true
      react = true
      extends = ["eslint:recommended", "@typescript-eslint/recommended"]
    '';
    ecosystems = ["nodejs"];
  };
}