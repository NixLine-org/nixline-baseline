# NixLine Baseline

The **NixLine Baseline** defines the foundational Nix expressions and policies used by all repositories in the [NixLine-org](https://github.com/NixLine-org) organization.  
It provides the shared Nix logic, governance rules and automation logic that all NixLine consumer repositories rely on.

---

## Purpose

NixLine workflows (such as CI, SBOM generation, dependency updates and policy checks) depend on a *baseline flake* that exposes at least two Nix applications:

- `#sync` — performs baseline setup or synchronization tasks.
- `#check` — validates repository configuration or compliance.

These serve as entry points for the reusable workflows in the `.github` repository.  
When run in a consumer repository, they apply or verify policies consistently across the organization.

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

Or run locally from a cloned copy:

```bash
nix run .#sync
nix run .#check
```

**Expected output:**

```bash
Hello, world!
```

---

## Tagging Policy

This repository is versioned via the `stable` tag to provide a consistent reference point for NixLine workflows.

To update the tag after any change:

```bash
git push origin main
git tag -d stable
git push origin :refs/tags/stable
git tag -a stable -m "Update stable tag after baseline changes"
git push origin stable
```

Always verify CI passes before re-tagging `stable`.

---

## Importance of the Baseline

This repository serves as the **official baseline** for NixLine.  
It defines how organizational workflows interpret and apply shared policy, serving as the root of consistency and traceability for all consumer repositories.

When another organization forks NixLine, this repository is where they establish **their own lineage path** — defining what policies, governance and automation rules will apply across their environment.  
By maintaining and versioning this baseline, each organization can evolve its own standards while still inheriting the reproducible and declarative structure that NixLine provides.

---

## Future Development

Future versions will extend the baseline with:

- Policy packs (CODEOWNERS, LICENSE, SECURITY.md, pre-commit, SBOM, etc.)
- Nix modules and automation for scalable governance
- Enhanced validation and synchronization logic for multi-repo environments
