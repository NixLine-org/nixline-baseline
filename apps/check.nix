{ pkgs, lib, helpers, packsLib }:

/*
  Validates that policy files in the current repository match the baseline.
  Uses the shared mkCheckApp factory.

  Usage:
    Direct Consumption (Recommended):
      nix run github:ORG/lineage-baseline#check
      nix run github:ORG/lineage-baseline#check -- --packs editorconfig,license
      nix run github:ORG/lineage-baseline#check -- --exclude security

    Template-Based Consumption:
      nix run .#check
      nix run .#check -- --packs editorconfig,license
      nix run .#check -- --config .lineage.toml
*/

let
  mkCheckApp = import ../lib/mk-check-app.nix;
  baselinePath = toString ./..;
in
mkCheckApp {
  inherit pkgs lib;
  name = "lineage-check";

  # Use the pinned nixpkgs from the flake
  pkgsExpression = "(builtins.getFlake \"${baselinePath}\").inputs.nixpkgs.legacyPackages.$CURRENT_SYSTEM";

  # Load packs from the baseline library
  packsLoaderSnippet = "(import ${baselinePath}/lib/packs.nix { inherit pkgs lib config; }).packModules";
}