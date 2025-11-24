{
  description = "Lineage Baseline Importer - Library for importing governance repositories";

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
      lib = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          lib = nixpkgs.lib;
        in
          import ./importer.nix { inherit pkgs lib; }
      );

      # Documentation examples (no actual fetching)
      examples = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          lib = nixpkgs.lib;
          importer = self.lib.${system};
        in
          {
            # Example function usage patterns
            exampleUsage = {
              # How to check if a file is governance file
              isLicense = importer.isGovernanceFile "LICENSE";
              isGitignore = importer.isGovernanceFile ".gitignore";
              isRandomFile = importer.isGovernanceFile "main.js";

              # How to generate pack names
              licensePackName = importer.generatePackName "LICENSE";
              gitignorePackName = importer.generatePackName ".gitignore";
              precommitPackName = importer.generatePackName ".pre-commit-config.yaml";
            };

            # Template for users to copy and modify
            usageTemplate = ''
              # Add this to your flake inputs:
              governance-repo = {
                url = "github:your-org/your-governance-repo";
                flake = false;
              };

              # In your outputs:
              importedPacks = importer.importFromSource inputs.governance-repo;
            '';
          }
      );
    };
}