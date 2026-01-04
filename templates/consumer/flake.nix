{
  description = "Lineage consumer repository with TOML configuration and external pack support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/fb7944c166a3b630f177938e478f0378e64ce108";
    lineage-baseline = {
      url = "github:Lineage-org/lineage-baseline?ref=stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # External pack sources (add your organization's pack repositories here)
    # Example:
    # myorg-security-packs = {
    #   url = "github:myorg/lineage-security-packs?ref=v1.2.0";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # myorg-language-packs = {
    #   url = "github:myorg/lineage-language-packs?ref=main";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = inputs@{ self, nixpkgs, lineage-baseline, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    in
    {
      # Expose pack loader for the sync app to use via nix eval
      lib = {
        mkCombinedPacks = { pkgs, lib, config }:
          let
            system = pkgs.system;
            baseline = lineage-baseline.lib.${system};
            
            # Re-initialize packs with the provided configuration
            # This ensures that parameterized packs get the runtime config
            baselinePacks = import "${lineage-baseline}/lib/packs.nix" { inherit pkgs lib config; };

            # Collect external pack sources from flake inputs
            # Filter out standard inputs (self, nixpkgs, lineage-baseline)
            standardInputs = [ "self" "nixpkgs" "lineage-baseline" ];
            externalPackInputs = lib.filterAttrs (name: _: !(lib.elem name standardInputs)) inputs;

            # Load external pack registries from flake inputs
            loadExternalPackRegistry = inputName: input:
              let
                # Assume external pack flakes expose lib.${system}.packs
                externalLib = input.lib.${system} or {};
                externalPacks = externalLib.packs or {};
              in
                # Prefix pack names with input name for namespacing
                lib.mapAttrs' (packName: pack: {
                  name = "${inputName}/${packName}";
                  # Re-apply config if the external pack is a function
                  value = if builtins.isFunction pack 
                          then pack { inherit pkgs lib config; }
                          else pack; 
                }) externalPacks;

            # Combine all external pack registries
            allExternalPacks = lib.foldl' (acc: inputPair:
              acc // (loadExternalPackRegistry inputPair.name inputPair.value)
            ) {} (lib.mapAttrsToList (name: value: { inherit name value; }) externalPackInputs);

            # Combined pack registry (baseline + external)
            combinedPacks = baselinePacks.packModules // allExternalPacks;
          in
            combinedPacks;
      };

      # Expose apps from baseline with TOML configuration support
      apps = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          lib = nixpkgs.lib;
          baseline = lineage-baseline.lib.${system};

          # Configuration-driven sync app with external pack support
          # Uses the robust factory from baseline to ensure feature parity
          sync = baseline.mkSyncApp {
            inherit pkgs lib;
            name = "lineage-sync";
            
            # Use the consumer's flake context to access combined packs
            pkgsExpression = "(builtins.getFlake (toString ./.)).inputs.nixpkgs.legacyPackages.$CURRENT_SYSTEM";
            packsLoaderSnippet = "(builtins.getFlake (toString ./.)).lib.mkCombinedPacks { inherit pkgs lib config; }";
          };

          # Flake update app - updates flake.lock
          flake-update = pkgs.writeShellApplication {
            name = "lineage-flake-update";
            runtimeInputs = [ pkgs.git pkgs.gh ];
            text = ''
              echo "╔════════════════════════════════════════════════════════════╗"
              echo "║                 Lineage Flake Update                       ║"
              echo "╚════════════════════════════════════════════════════════════╝"
              echo ""

              # Update flake.lock
              echo "Updating flake.lock..."
              nix flake update
              echo "✓ flake.lock updated"
              echo ""

              # Check if there are changes
              if ! git diff --quiet flake.lock;
              then
                echo "Changes detected, creating branch and PR..."

                BRANCH="automated/flake-update-$(date +%Y%m%d-%H%M%S)"
                git checkout -b "$BRANCH"
                git add flake.lock
                git commit -m "chore(nix): update flake.lock"
                git push -u origin "$BRANCH"

                gh pr create \
                  --title "chore(nix): update flake.lock" \
                  --body "Automated flake.lock update" \
                  --label "dependencies,nix,automated"

                echo "✓ PR created"
              else
                echo "No changes to flake.lock"
              fi
            '';
          };

          # Setup hooks app - installs pre-commit hooks
          setup-hooks = pkgs.writeShellApplication {
            name = "lineage-setup-hooks";
            runtimeInputs = [ pkgs.git pkgs.pre-commit ];
            text = ''
              echo "╔════════════════════════════════════════════════════════════╗"
              echo "║                Lineage Setup Hooks                         ║"
              echo "╚════════════════════════════════════════════════════════════╝"
              echo ""

              # Install pre-commit hooks
              echo "Installing pre-commit hooks..."
              pre-commit install
              echo "✓ Pre-commit hooks installed"
              echo ""

              # Run hooks on all files to verify
              echo "Testing hooks on all files..."
              pre-commit run --all-files || true
              echo ""
              echo "Setup complete. Hooks will run automatically on git commit."
            '';
          };

          # Configuration-driven check app
          # Validates files against baseline using same config as sync
          # Supports passing additional arguments like --override
          check = baseline.mkCheckApp {
            inherit pkgs lib;
            name = "lineage-check";
            
            # Use the consumer's flake context to access combined packs
            pkgsExpression = "(builtins.getFlake (toString ./.)).inputs.nixpkgs.legacyPackages.$CURRENT_SYSTEM";
            packsLoaderSnippet = "(builtins.getFlake (toString ./.)).lib.mkCombinedPacks { inherit pkgs lib config; }";
          };

          # SBOM app - pure Nix app (no file materialization)
          sbom = let
            formats = [ "cyclonedx-json" "spdx-json" ];
            scanTarget = ".";
            outputDir = "sbom-output";
          in
          pkgs.writeShellApplication {
            name = "generate-sbom";
            runtimeInputs = [ pkgs.syft ];
            text = ''
              echo "════════════════════════════════════════════════════════════"
              echo "  Generating SBOM"
              echo "════════════════════════════════════════════════════════════"
              echo ""
              echo "Target: ${scanTarget}"
              echo "Formats: ${lib.concatStringsSep ", " formats}"
              echo "Output: ${outputDir}/"
              echo ""

              mkdir -p ${outputDir}

              ${lib.concatMapStringsSep "\n" (format: ''
                echo "Generating ${format} SBOM..."
                syft dir:${scanTarget} -o ${format} > ${outputDir}/sbom.${format}
                echo "✓ ${outputDir}/sbom.${format}"
              '') formats}

              echo ""
              echo "SBOM generation complete"
              echo ""
              echo "Files generated:"
              ls -lh ${outputDir}/
            '';
          };
        in
        {
          # Sync persistent policy files (commit these)
          sync = {
            type = "app";
            program = "${sync}/bin/lineage-sync";
          };

          # Check persistent files match baseline
          check = {
            type = "app";
            program = "${check}/bin/lineage-check";
          };

          # Pure apps (no file materialization)
          sbom = {
            type = "app";
            program = "${sbom}/bin/generate-sbom";
          };

          flake-update = {
            type = "app";
            program = "${flake-update}/bin/lineage-flake-update";
          };

          setup-hooks = {
            type = "app";
            program = "${setup-hooks}/bin/lineage-setup-hooks";
          };
        }
      );
    };
}