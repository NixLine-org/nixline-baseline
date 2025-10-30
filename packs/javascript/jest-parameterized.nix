{ pkgs, lib, config ? {} }:

#
# JEST PACK (Parameterized)
#
# JavaScript/TypeScript testing framework configuration.
# Provides test configuration with ecosystem-aware settings for Node.js projects.
#

let
  cfg = config.jest or {};

  # Default configuration
  testEnvironment = cfg.test_environment or "node";
  collectCoverage = cfg.collect_coverage or true;
  coverageThreshold = cfg.coverage_threshold or {
    global = {
      branches = 80;
      functions = 80;
      lines = 80;
      statements = 80;
    };
  };
  coverageDirectory = cfg.coverage_directory or "coverage";
  testMatch = cfg.test_match or [
    "**/__tests__/**/*.(js|jsx|ts|tsx)"
    "**/*.(test|spec).(js|jsx|ts|tsx)"
  ];

  # TypeScript support
  isTypeScript = cfg.typescript or false;
  preset = if isTypeScript then "ts-jest" else null;
  transform = if isTypeScript then {
    "^.+\\.tsx?$" = "ts-jest";
  } else {};

  # React support
  isReact = cfg.react or false;
  setupFilesAfterEnv = if isReact then ["<rootDir>/src/setupTests.js"] else [];
  testEnvironmentReact = if isReact then "jsdom" else testEnvironment;

  jestConfig = {
    testEnvironment = testEnvironmentReact;
    collectCoverage = collectCoverage;
    coverageDirectory = coverageDirectory;
    coverageThreshold = coverageThreshold;
    testMatch = testMatch;
    setupFilesAfterEnv = setupFilesAfterEnv;
  } // lib.optionalAttrs isTypeScript {
    preset = preset;
    transform = transform;
  };

in
{
  files = {
    "jest.config.js" = ''
      module.exports = ${builtins.toJSON jestConfig};
    '';
  };

  checks = [
    {
      name = "jest-config-present";
      check = ''
        if [[ -f "jest.config.js" || -f "jest.config.json" || -f "package.json" ]]; then
          echo "[+] Jest configuration found"
        else
          echo "[-] Jest configuration missing"
          exit 1
        fi
      '';
    }
    {
      name = "jest-available";
      check = ''
        if command -v jest >/dev/null 2>&1 || npm list jest >/dev/null 2>&1; then
          echo "[+] Jest is available"
        else
          echo "[!] Jest not available (install: npm install jest)"
        fi
      '';
    }
  ];

  meta = {
    description = "Jest testing framework configuration for JavaScript/TypeScript";
    homepage = "https://jestjs.io/";
    example = ''
      # Configuration in .nixline.toml:
      [packs.jest]
      typescript = true
      react = true
      collect_coverage = true
      test_environment = "jsdom"
    '';
    ecosystems = ["nodejs"];
  };
}