# NixLine Packs Library
#
# Central registry and loader for all pack modules in the baseline.
# Manages pack imports, configuration passing, and external pack references.

{ pkgs, lib, config ? {} }:

let
  # Import all pack modules with configuration
  packModules = {
    # Universal packs (all languages/ecosystems)
    editorconfig = import ../packs/universal/editorconfig-parameterized.nix { inherit pkgs lib config; };
    license = import ../packs/universal/license-parameterized.nix { inherit pkgs lib config; };
    security = import ../packs/universal/security-parameterized.nix { inherit pkgs lib config; };
    codeowners = import ../packs/universal/codeowners-parameterized.nix { inherit pkgs lib config; };
    precommit = import ../packs/universal/precommit-parameterized.nix { inherit pkgs lib config; };
    dependabot = import ../packs/universal/dependabot-parameterized.nix { inherit pkgs lib config; };
    gitignore = import ../packs/universal/gitignore-parameterized.nix { inherit pkgs lib config; };
    prettier = import ../packs/universal/prettier-parameterized.nix { inherit pkgs lib config; };
    yamllint = import ../packs/universal/yamllint-parameterized.nix { inherit pkgs lib config; };

    # Python ecosystem packs
    bandit = import ../packs/python/bandit.nix { inherit pkgs lib config; };
    flake8 = import ../packs/python/flake8-parameterized.nix { inherit pkgs lib config; };

    # JavaScript/Node.js ecosystem packs
    eslint = import ../packs/javascript/eslint-parameterized.nix { inherit pkgs lib config; };
    jest = import ../packs/javascript/jest-parameterized.nix { inherit pkgs lib config; };

    # Rust ecosystem packs
    "rust/clippy" = import ../packs/rust/clippy.nix { inherit pkgs lib config; };
    "rust/rustfmt" = import ../packs/rust/rustfmt.nix { inherit pkgs lib config; };

    # Go ecosystem packs
    "go/gofmt" = import ../packs/go/gofmt.nix { inherit pkgs lib config; };
    "go/golangci-lint" = import ../packs/go/golangci-lint.nix { inherit pkgs lib config; };
  };

  # Load external pack sources (placeholder for future implementation)
  # Note: Full external pack loading requires flake inputs, which are resolved at sync time
  # This function prepares the structure for external pack references
  loadExternalPacks = externalSources: externalPackRefs:
    let
      # External pack loading is intentionally disabled to maintain pure evaluation
      # External packs are handled at sync time via the migrate-governance app
      # This preserves reproducibility and avoids impure builtins.getFlake calls
      loadExternalSource = sourceName: sourceSpec:
        if false  # Disabled for pure evaluation
        then {} # builtins.getFlake sourceSpec.url
        else {};

      externalPackModules = lib.mapAttrs loadExternalSource externalSources;
    in
      externalPackModules;

  # Parse comma-separated pack list from environment
  parsePackList = packsEnv:
    if packsEnv == null || packsEnv == ""
    then []
    else lib.splitString "," packsEnv;

  # Select packs based on NIXLINE_PACKS environment variable
  selectPacks = packsEnv:
    let
      requestedPacks = parsePackList packsEnv;
    in
      lib.filterAttrs (name: _: lib.elem name requestedPacks) packModules;

  # Merge all files from selected packs
  mergePackFiles = packs:
    lib.foldl' (acc: pack: acc // pack.files) {} (lib.attrValues packs);

  # Merge all checks from selected packs
  mergePackChecks = packs:
    lib.concatMap (pack: pack.checks or []) (lib.attrValues packs);

  # Combine internal and external packs into unified registry
  combinePackRegistries = internalPacks: externalPacks:
    internalPacks // externalPacks;

  # Select packs from combined registry (internal + external)
  selectFromCombinedPacks = combinedPacks: packList:
    let
      requestedPacks = if builtins.isList packList then packList else parsePackList packList;
    in
      lib.filterAttrs (name: _: lib.elem name requestedPacks) combinedPacks;

in {
  inherit
    packModules
    loadExternalPacks
    selectPacks
    mergePackFiles
    mergePackChecks
    combinePackRegistries
    selectFromCombinedPacks;

  # Get all files to materialize based on environment variable
  getFiles = packsEnv: mergePackFiles (selectPacks packsEnv);

  # Get all checks to run based on environment variable
  getChecks = packsEnv: mergePackChecks (selectPacks packsEnv);

  # Get files from combined pack registry (supports external packs)
  getFilesFromCombined = combinedPacks: packList:
    mergePackFiles (selectFromCombinedPacks combinedPacks packList);

  # Get checks from combined pack registry (supports external packs)
  getChecksFromCombined = combinedPacks: packList:
    mergePackChecks (selectFromCombinedPacks combinedPacks packList);
}
