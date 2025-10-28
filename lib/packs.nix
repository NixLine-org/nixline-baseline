{ pkgs, lib, config ? {} }:

let
  # Import all pack modules with configuration
  packModules = {
    # Persistent packs (committed to consumer repos)
    editorconfig = import ../packs/editorconfig-parameterized.nix { inherit pkgs lib config; };
    license = import ../packs/license-parameterized.nix { inherit pkgs lib config; };
    security = import ../packs/security-parameterized.nix { inherit pkgs lib config; };
    codeowners = import ../packs/codeowners-parameterized.nix { inherit pkgs lib config; };
    precommit = import ../packs/precommit-parameterized.nix { inherit pkgs lib config; };
    dependabot = import ../packs/dependabot-parameterized.nix { inherit pkgs lib config; };

    # Pure apps in consumer flakes (no pack files):
    # - sbom: nix run .#sbom
    # - flake-update: nix run .#flake-update
    # - setup-hooks: nix run .#setup-hooks
  };

  # Load external pack sources (placeholder for future implementation)
  # Note: Full external pack loading requires flake inputs, which are resolved at sync time
  # This function prepares the structure for external pack references
  loadExternalPacks = externalSources: externalPackRefs:
    let
      # For now, return empty set - external packs will be handled in sync app
      # TODO: Implement dynamic flake loading when called from sync context
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
