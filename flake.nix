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
          configLib = import ./lib/config.nix { inherit pkgs lib; };

          # Import apps
          syncApp = import ./apps/sync.nix { inherit pkgs lib helpers packsLib; };
          checkApp = import ./apps/check.nix { inherit pkgs lib helpers packsLib; };
          importPolicyApp = import ./apps/import-policy.nix { inherit pkgs lib; };
          fetchLicenseApp = import ./apps/fetch-license.nix { inherit pkgs lib; };
          createPackApp = import ./apps/create-pack.nix { inherit pkgs lib; };
          listLicensesApp = import ./apps/list-licenses.nix { inherit pkgs; };
          extractConfigApp = import ./apps/extract-config.nix { inherit pkgs lib; };
          migrateGovernanceApp = import ./apps/migrate-governance.nix { inherit pkgs lib; };
        in
        {
          sync = {
            type = "app";
            program = "${syncApp}/bin/nixline-sync";
            meta = {
              description = "Materialize policy files from baseline with configuration support";
              license = lib.licenses.asl20;
            };
          };

          check = {
            type = "app";
            program = "${checkApp}/bin/nixline-check";
            meta = {
              description = "Validate that policy files match baseline";
              license = lib.licenses.asl20;
            };
          };

          import-policy = {
            type = "app";
            program = "${importPolicyApp}/bin/nixline-import-policy";
            meta = {
              description = "Import existing policy files into pack format";
              license = lib.licenses.asl20;
            };
          };

          fetch-license = {
            type = "app";
            program = "${fetchLicenseApp}/bin/nixline-fetch-license";
            meta = {
              description = "Fetch license text from SPDX and generate license pack";
              license = lib.licenses.asl20;
            };
          };

          list-licenses = {
            type = "app";
            program = "${listLicensesApp}/bin/list-licenses";
            meta = {
              description = "List supported license types and configuration examples";
              license = lib.licenses.asl20;
            };
          };
          extract-config = {
            type = "app";
            program = "${extractConfigApp}/bin/nixline-extract-config";
            meta = {
              description = "Extract configuration from existing files to generate .nixline.toml sections";
              license = lib.licenses.asl20;
            };
          };
          migrate-governance = {
            type = "app";
            program = "${migrateGovernanceApp}/bin/nixline-migrate-governance";
            meta = {
              description = "Migrate existing governance repositories to create custom NixLine baselines";
              license = lib.licenses.asl20;
            };
          };

          create-pack = {
            type = "app";
            program = "${createPackApp}/bin/nixline-create-pack";
            meta = {
              description = "Create a new policy pack with template structure";
              license = lib.licenses.asl20;
            };
          };

        }
      );
    };
}
