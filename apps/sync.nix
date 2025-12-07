{ pkgs, lib, helpers, packsLib }:

/*
  Enhanced sync app using the shared mkSyncApp factory.
  This maintains the robust functionality for Direct Consumption users.

  Usage:
    Direct Consumption (Recommended):
      nix run github:ORG/lineage-baseline#sync
      nix run github:ORG/lineage-baseline#sync -- --dry-run
      nix run github:ORG/lineage-baseline#sync -- --override org.name=MyCompany

    Template-Based Consumption:
      nix run .#sync
      nix run .#sync -- --dry-run
      nix run .#sync -- --backup
*/

let
  mkSyncApp = import ../lib/mk-sync-app.nix;
  baselinePath = toString ./..;
in
mkSyncApp {
  inherit pkgs lib;
  name = "lineage-sync";

  # Use the pinned nixpkgs from the flake
  pkgsExpression = "(builtins.getFlake \"${baselinePath}\").inputs.nixpkgs.legacyPackages.\${builtins.currentSystem}";

  # Load packs from the baseline library
  packsLoaderSnippet = "(import ${baselinePath}/lib/packs.nix { inherit pkgs lib config; }).packModules";
}