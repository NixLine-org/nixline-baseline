{ pkgs, lib, helpers, packsLib }:

/*
  Validates that policy files in the current repository match the baseline.
  Uses the shared mkCheckApp factory.
*/

let
  mkCheckApp = import ../lib/mk-check-app.nix;
  baselinePath = toString ./..;
in
mkCheckApp {
  inherit pkgs lib;
  name = "lineage-check";

  # Use the pinned nixpkgs from the flake
  pkgsExpression = "(builtins.getFlake \"${baselinePath}\").inputs.nixpkgs.legacyPackages.\${builtins.currentSystem}";

  # Load packs from the baseline library
  packsLoaderSnippet = "(import ${baselinePath}/lib/packs.nix { inherit pkgs lib config; }).packModules";
}