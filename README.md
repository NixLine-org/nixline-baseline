<p align="center">
  <img src="assets/lineage_banner.png" alt="Lineage — Policy Governance via Nix" width="100%">
</p>

# Lineage Baseline

[![Update Nixpkgs](https://github.com/Lineage-org/lineage-baseline/actions/workflows/update-nixpkgs.yml/badge.svg)](https://github.com/Lineage-org/lineage-baseline/actions/workflows/update-nixpkgs.yml)
[![Promote to Stable](https://github.com/Lineage-org/lineage-baseline/actions/workflows/promote-to-stable.yml/badge.svg)](https://github.com/Lineage-org/lineage-baseline/actions/workflows/promote-to-stable.yml)

**Tags:** [![Unstable](https://img.shields.io/github/v/tag/Lineage-org/lineage-baseline?filter=unstable&label=unstable&color=orange)](https://github.com/Lineage-org/lineage-baseline/releases/tag/unstable) [![Stable](https://img.shields.io/github/v/tag/Lineage-org/lineage-baseline?filter=stable&label=stable&color=green)](https://github.com/Lineage-org/lineage-baseline/releases/tag/stable)

The **Lineage Baseline** defines the foundational Nix expressions and policies used by all repositories in the [Lineage-org](https://github.com/Lineage-org) organization. It provides shared Nix logic, governance rules, and automation logic.

> **⚠️ Development Status**: Lineage is under active development.
> - **For production use**: Pin to the `stable` tag: `github:Lineage-org/lineage-baseline?ref=stable`
> - **For testing**: Use `unstable` branch

## Documentation

- [**Architecture**](docs/architecture.md) - How Lineage works, propagation, and patterns.
- [**Usage Guide**](docs/usage.md) - CLI commands, configuration reference (`.lineage.toml`), and pack details.
- [**Governance Migration**](docs/migration.md) - Tools to migrate existing repositories.
- [**Security**](docs/security.md) - Security policies and supply chain details.

## Key Benefits

- **Pure Upstream Consumption**: Use Lineage baseline directly without forking.
- **Configuration-Driven**: Customize via `.lineage.toml` without maintaining code.
- **Smart Merging**: Intelligent 3-way merge preserves your local changes during updates.
- **Governance Migration**: Automatic conversion of existing governance repositories.
- **GitHub Actions**: Ready-to-use actions for CI/CD.

## Quick Start

### 1. GitHub Actions (Recommended)

Add the Lineage Action to your workflow to enforce policies:

```yaml
jobs:
  lineage-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - uses: Lineage-org/lineage-baseline@stable
        with:
          command: check
          # Optional: select specific packs
          packs: editorconfig,license
```

### 2. Direct Consumption

Run directly from the command line:

```bash
# Sync default policies
nix run github:Lineage-org/lineage-baseline#sync

# Sync with configuration
nix run github:Lineage-org/lineage-baseline#sync -- --config .lineage.toml

# Preview changes
nix run github:Lineage-org/lineage-baseline#sync -- --dry-run
```

### 3. Template Initialization

Initialize a new repository with Lineage support:

```bash
nix flake init -t github:Lineage-org/lineage-baseline
nix run .#sync
```

## Usage

Lineage provides powerful apps for policy management. See [Usage Guide](docs/usage.md) for full details.

**Sync Policies:**
```bash
nix run github:Lineage-org/lineage-baseline#sync -- --interactive
```

**Validate Policies:**
```bash
nix run github:Lineage-org/lineage-baseline#check
```

**Create Pack:**
```bash
nix run github:Lineage-org/lineage-baseline#create-pack mypack
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.