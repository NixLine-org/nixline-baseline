{
  description = "Lineage consumer repository with TOML configuration and external pack support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/050e09e091117c3d7328c7b2b7b577492c43c134";
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
      # Expose apps from baseline with TOML configuration support
      apps = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          lib = nixpkgs.lib;
          baseline = lineage-baseline.lib.${system};

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
                value = pack;
              }) externalPacks;

          # Combine all external pack registries
          allExternalPacks = lib.foldl' (acc: inputPair:
            acc // (loadExternalPackRegistry inputPair.name inputPair.value)
          ) {} (lib.mapAttrsToList (name: value: { inherit name value; }) externalPackInputs);

          # Combined pack registry (baseline + external)
          combinedPacks = baseline.packs // allExternalPacks;

          # Generate pack files with configuration support
          generatePackFiles = config: enabledPackNames:
            let
              # Parse pack list and filter available packs
              packList = if builtins.isList enabledPackNames then enabledPackNames else lib.splitString "," enabledPackNames;
              availablePacks = lib.filterAttrs (name: _: lib.elem name packList) combinedPacks;

              # Apply configuration to each pack and get files
              applyConfigToPack = packName: pack:
                if builtins.isFunction pack
                then (pack { inherit pkgs lib config; }).files or {}
                else pack.files or {};

              # Merge all files from selected packs
              allFiles = lib.foldl' (acc: packFiles: acc // packFiles) {}
                         (lib.mapAttrsToList applyConfigToPack availablePacks);
            in
              allFiles;

          # Configuration-driven sync app with external pack support
          sync = pkgs.writeShellApplication {
            name = "lineage-sync";
            runtimeInputs = with pkgs; [ jq remarshal ];
            text = ''
              echo "╔════════════════════════════════════════════════════════════╗"
              echo "║                Lineage Sync (with External Packs)         ║"
              echo "╚════════════════════════════════════════════════════════════╝"
              echo ""

              # Show available packs
              echo "Available packs:"
              echo "  Built-in packs:"
              ${lib.concatStringsSep "\n" (map (name: "echo \"    - ${name}\"") (lib.attrNames baseline.packs))}
              ${lib.optionalString (allExternalPacks != {}) ''
                echo "  External packs:"
                ${lib.concatStringsSep "\n" (map (name: "echo \"    - ${name}\"") (lib.attrNames allExternalPacks))}
              ''}
              echo ""

              # Default configuration and pack list
              DEFAULT_CONFIG='${builtins.toJSON {
                organization = { name = "Lineage-org"; email = "opensource@example.com"; };
                packs = { enabled = [ "editorconfig" "codeowners" "security" "license" "precommit" "dependabot" ]; };
              }}'

              CONFIG_FILE=".lineage.toml"
              if [[ -f "$CONFIG_FILE" ]]; then
                echo "Using configuration: $CONFIG_FILE"
                CONFIG_JSON=$(remarshal -if toml -of json < "$CONFIG_FILE" 2>/dev/null || echo "$DEFAULT_CONFIG")
              else
                echo "No .lineage.toml found, using defaults"
                CONFIG_JSON="$DEFAULT_CONFIG"
              fi

              # Extract enabled packs
              ENABLED_PACKS=$(echo "$CONFIG_JSON" | jq -r '.packs.enabled[]?' | tr '\n' ',' | sed 's/,$//')
              if [[ -z "$ENABLED_PACKS" ]]; then
                ENABLED_PACKS="editorconfig,codeowners,security,license,precommit,dependabot"
              fi

              echo "Enabled packs: $ENABLED_PACKS"
              echo ""

              # Generate and materialize files
              ${let
                # Generate files for all possible pack combinations
                allPossiblePacks = lib.attrNames combinedPacks;
                maxConfig = { organization = { name = "TemplateOrg"; email = "test@example.com"; }; packs = {}; };

                # Generate materialization script for each pack
                materializeScript = packName: pack:
                  let
                    # Get pack files with template config
                    packFiles = if builtins.isFunction pack
                               then (pack { inherit pkgs lib; config = maxConfig; }).files or {}
                               else pack.files or {};
                  in
                    lib.concatStringsSep "\n" (lib.mapAttrsToList (path: content: ''
                      if [[ ",$ENABLED_PACKS," == *",${packName},"* ]]; then
                        mkdir -p "$(dirname "${path}")"
                        cat > "${path}" << 'LINEAGE_EOF'
                      ${content}
                      LINEAGE_EOF
                        echo "✓ ${path} (from ${packName})"
                      fi
                    '') packFiles);

              in lib.concatStringsSep "\n" (lib.mapAttrsToList materializeScript combinedPacks)}

              echo ""
              echo "Sync complete! Files have been materialized."
              echo "Run 'git add .' to stage the changes."
            '';
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
              if ! git diff --quiet flake.lock; then
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
          check = pkgs.writeShellApplication {
            name = "lineage-check";
            runtimeInputs = with pkgs; [ jq remarshal ];
            text = ''
              echo "╔════════════════════════════════════════════════════════════╗"
              echo "║                   Lineage Check                            ║"
              echo "╚════════════════════════════════════════════════════════════╝"
              echo ""

              # Pass through additional arguments like --override
              ADDITIONAL_ARGS="$@"

              CONFIG_FILE=".lineage.toml"
              if [[ -f "$CONFIG_FILE" ]]; then
                echo "Using configuration: $CONFIG_FILE"
                eval "${lineage-baseline.apps.${system}.check.program} --config \"$CONFIG_FILE\" $ADDITIONAL_ARGS"
              else
                echo "No .lineage.toml found, using default configuration"
                eval "${lineage-baseline.apps.${system}.check.program} $ADDITIONAL_ARGS"
              fi
            '';
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
