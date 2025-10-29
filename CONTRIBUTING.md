# Contributing to NixLine Baseline

Thanks for contributing to NixLine! This is the baseline repository that defines the core policy packs and apps.

## Prerequisites

You'll need Nix installed. If you don't have it, we recommend the [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer) for the best experience.

## Quick Start

Clone the repo and test that everything works:

```bash
git clone https://github.com/NixLine-org/nixline-baseline.git
cd nixline-baseline
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