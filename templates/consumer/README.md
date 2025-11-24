# Lineage Consumer Template

This template provides a complete Lineage consumer repository with TOML configuration and external pack support.

## Features

- **Configuration-driven**: Use `.lineage.toml` to customize packs and settings
- **Upstream consumption**: Consume baseline directly without forking
- **External pack support**: Add your organization's custom packs via flake inputs
- **Version pinning**: Flake.lock ensures reproducible builds
- **Local apps**: Run policy management through local flake apps

## Quick Start

```bash
# Initialize from template
nix flake new -t github:Lineage-org/lineage-baseline my-repo
cd my-repo

# Customize configuration
vim .lineage.toml

# Sync policy files
nix run .#sync

# Validate policy files
nix run .#check

# Update baseline dependency
nix run .#flake-update
```

## Configuration

The `.lineage.toml` file controls pack selection and customization:

```toml
[organization]
name = "MyOrg"
email = "opensource@myorg.com"

[packs]
enabled = ["editorconfig", "license", "security", "codeowners"]

[packs.license]
type = "mit"

[packs.codeowners]
default_team = "@myorg/engineering"
```

## External Packs

Add your organization's custom packs by modifying `flake.nix`:

```nix
inputs = {
  # ... existing inputs ...
  myorg-security-packs = {
    url = "github:myorg/lineage-security-packs?ref=v1.2.0";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

Then reference them in `.lineage.toml`:

```toml
[packs]
enabled = [
  "editorconfig",
  "license",
  "myorg-security-packs/custom-security"  # External pack
]
```

## Available Apps

- `nix run .#sync` - Materialize policy files from baseline + external packs
- `nix run .#check` - Validate files match baseline configuration
- `nix run .#flake-update` - Update flake.lock and create PR
- `nix run .#setup-hooks` - Install pre-commit hooks
- `nix run .#sbom` - Generate software bill of materials

## GitHub Actions Integration

The template works seamlessly with Lineage GitHub workflows:

```yaml
# .github/workflows/ci.yml
jobs:
  lineage-ci:
    uses: Lineage-org/.github/.github/workflows/lineage-ci.yml@stable
    with:
      consumption_pattern: template
      config_file: .lineage.toml
```

## Benefits

- **No forking required**: Consume baseline as upstream dependency
- **External pack support**: Add organization-specific packs without forking baseline
- **Automatic updates**: Get policy updates via flake.lock updates
- **Full customization**: Override any setting through TOML configuration
- **Reproducible**: Flake.lock pins exact baseline and external pack versions
- **Local development**: All tools available via nix run commands