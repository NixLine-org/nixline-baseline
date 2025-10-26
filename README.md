# NixLine Baseline (Demo)

The **NixLine Baseline** defines the foundational Nix expressions and policies used by all repositories in the [NixLine-org](https://github.com/NixLine-org) organization.  
This **demo version** provides minimal functionality to verify that the NixLine reusable GitHub workflows operate correctly in continuous integration environments.

---

## Purpose

NixLine workflows (such as CI, SBOM generation, dependency updates and policy checks) expect a *baseline flake* that exposes at least two Nix applications:

- `#sync` — performs baseline setup or synchronization tasks.
- `#check` — validates repository configuration or compliance.

In this demo, both commands simply run the `hello` binary from Nixpkgs to confirm the pipeline executes end-to-end.

---

## Usage

You can test the baseline directly from any Nix-enabled environment or CI runner:

```bash
nix run github:NixLine-org/nixline-baseline#sync
nix run github:NixLine-org/nixline-baseline#check
```

Explicitly pin to a ref (branch or tag):

```bash
# Use a branch
nix run 'github:NixLine-org/nixline-baseline?ref=main'#sync

# Use the stable tag
nix run 'github:NixLine-org/nixline-baseline?ref=stable'#check
```

OR

### Run locally (from this directory)

```bash
nix run .#sync
nix run .#check
```

**Expected output:**

```bash
Hello, world!
```

---

## Notes

This is **not** the production baseline; it is meant for workflow verification.

- Future versions will include:
  - Policy packs (CODEOWNERS, LICENSE, SECURITY.md, pre-commit, SBOM, etc.)
  - Nix modules and automation for org-wide governance
