# Contributing to NixLine Baseline

Thanks for contributing to NixLine! This is the baseline repository that defines the core policy packs and apps.

## Prerequisites

You'll need Nix installed. If you don't have it, we recommend the [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer) for the best experience.

## Development Workflow

This repository uses an automated branching workflow:

### Branch Structure

- **unstable**: Main development branch - all changes should be pushed here
- **main**: Stable integration branch - receives validated changes from unstable
- **stable tag**: Production releases - tagged automatically from main

### Making Changes

1. **Work on the unstable branch**: All development happens on `unstable`
   ```bash
   git checkout unstable
   git pull origin unstable
   # Make your changes
   git add .
   git commit -m "descriptive commit message"
   git push origin unstable
   ```

2. **Automatic validation**: Pushing to `unstable` triggers comprehensive validation:
   - Flake checks across all systems
   - App verification (sync, check, import-policy, fetch-license, list-licenses)
   - Content validation (no TODO/CHANGEME placeholders)

3. **Automatic promotion**: When validation passes:
   - A PR is automatically created to merge `unstable` → `main`
   - The PR is auto-approved and merged
   - The `unstable` tag is updated to track the latest `unstable` branch commit

4. **Stable promotion**: When changes reach `main`:
   - A stable candidate marker (`.stable-candidate`) is created
   - The stable promotion workflow is triggered automatically
   - The `stable` tag is updated for consumer repositories

## Quick Start

Clone the repo and test that everything works:

```bash
git clone https://github.com/NixLine-org/nixline-baseline.git
cd nixline-baseline
git checkout unstable
nix flake check
nix run .#sync -- --dry-run
```

## Project Structure

The `packs/` directory contains the core policy definitions that all NixLine consumers can use. The `examples/packs/` directory has language-specific examples like Python and JavaScript tooling that organizations can copy if needed.

Apps in `apps/` provide the sync, check and utility functionality. The `templates/` directory contains the consumer repository template.

## Adding New Packs

If you want to add a new core pack that all NixLine users should have access to, create it in `packs/` with parameterization support and add it to `lib/packs.nix`. Use the existing packs as examples.

For language-specific tools, consider adding them to `examples/packs/` instead so organizations can pick what they need.

## Testing Changes

Run `nix flake check` to validate syntax. Test the sync app with `nix run .#sync -- --dry-run` and try different pack combinations to make sure everything works.

You can test the consumer template by running `nix flake init -t .` in a temporary directory.

## Submitting Changes

Fork the repo, make your changes on a feature branch and open a pull request. Please include a clear description of what you're adding or fixing.

Keep changes focused and avoid breaking existing functionality. The baseline is used by many consumer repositories so stability matters.

## Questions

Open a GitHub issue if you have questions or want to discuss larger changes before implementing them.