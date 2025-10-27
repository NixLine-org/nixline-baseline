{
  description = "NixLine baseline - organization-wide CI governance and policy enforcement";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    in
    {
      # Flake templates for consumer repos
      templates = {
        consumer = {
          path = ./templates/consumer;
          description = "NixLine consumer repository template with flake inputs";
        };
        default = {
          path = ./templates/consumer;
          description = "NixLine consumer repository template with flake inputs";
        };
      };

      # Expose packs as importable outputs for consumer repos
      lib = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          lib = nixpkgs.lib;
          packsLib = import ./lib/packs.nix { inherit pkgs lib; };
        in
        {
          # Individual pack modules
          packs = packsLib.packModules;

          # Helper functions
          inherit (packsLib) selectPacks mergePackFiles mergePackChecks getFiles getChecks;
        }
      );

      apps = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          lib = nixpkgs.lib;

          # Import helper libraries
          helpers = import ./lib/default.nix { inherit pkgs; };
          packsLib = import ./lib/packs.nix { inherit pkgs lib; };

          # Import apps
          syncApp = import ./apps/sync.nix { inherit pkgs lib helpers packsLib; };
          checkApp = import ./apps/check.nix { inherit pkgs lib helpers packsLib; };
          importPolicyApp = import ./apps/import-policy.nix { inherit pkgs lib; };
          fetchLicenseApp = import ./apps/fetch-license.nix { inherit pkgs lib; };
        in
        {
          sync = {
            type = "app";
            program = "${syncApp}/bin/nixline-sync";
          };

          check = {
            type = "app";
            program = "${checkApp}/bin/nixline-check";
          };

          import-policy = {
            type = "app";
            program = "${importPolicyApp}/bin/nixline-import-policy";
          };

          fetch-license = {
            type = "app";
            program = "${fetchLicenseApp}/bin/nixline-fetch-license";
          };
        }
      );
    };
}
