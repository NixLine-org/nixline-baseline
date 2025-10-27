{ pkgs, lib }:

let
  # Import all pack modules
  packModules = {
    precommit = import ../packs/precommit.nix { inherit pkgs lib; };
    editorconfig = import ../packs/editorconfig.nix { inherit pkgs lib; };
    codeowners = import ../packs/codeowners.nix { inherit pkgs lib; };
    security = import ../packs/security.nix { inherit pkgs lib; };
    license = import ../packs/license.nix { inherit pkgs lib; };
    sbom = import ../packs/sbom.nix { inherit pkgs lib; };
    dependabot = import ../packs/dependabot.nix { inherit pkgs lib; };
    flake-update = import ../packs/flake-update.nix { inherit pkgs lib; };
  };

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

in {
  inherit packModules selectPacks mergePackFiles mergePackChecks;

  # Get all files to materialize based on environment variable
  getFiles = packsEnv: mergePackFiles (selectPacks packsEnv);

  # Get all checks to run based on environment variable
  getChecks = packsEnv: mergePackChecks (selectPacks packsEnv);
}
