# Usage Guide

## Enhanced Sync App

The sync app features **runtime configuration passing** following nix.dev best practices, enabling organizations to consume the baseline as pure upstream without forking.

**Basic Usage:**
```bash
# Default policies (no configuration)
nix run github:Lineage-org/lineage-baseline#sync

# Configuration-driven (organization branding)
nix run github:Lineage-org/lineage-baseline#sync -- --config .lineage.toml

# Preview changes without applying (shows diff)
nix run github:Lineage-org/lineage-baseline#sync -- --dry-run

# Interactive mode (ask before overwriting changed files)
nix run github:Lineage-org/lineage-baseline#sync -- --interactive

# Select specific packs
nix run github:Lineage-org/lineage-baseline#sync -- --packs editorconfig,license,codeowners

# Exclude packs from defaults
nix run github:Lineage-org/lineage-baseline#sync -- --exclude security,dependabot

# CLI overrides (runtime customization)
nix run github:Lineage-org/lineage-baseline#sync -- --override org.name=MyCompany
nix run github:Lineage-org/lineage-baseline#sync -- --override org.email=security@lineage.run

# Combine options
nix run github:Lineage-org/lineage-baseline#sync -- --config .lineage.toml --override org.name=TestCorp --dry-run
```

### Smart Merging & State Tracking

Lineage tracks the state of synced files in `.lineage/state/`. This allows for intelligent updates:

- **State Exists:** If you modify a file locally, `sync` will attempt a 3-way merge between the old baseline (state), the new baseline, and your local changes.
- **Conflict:** If a merge conflict occurs, conflict markers are added to the file.
- **Interactive Mode:** Use `--interactive` to manually choose between `[y]es` (overwrite), `[n]o` (skip), or `[m]erge`.

**Other Apps:**
```bash
# Validate policies match baseline
nix run github:Lineage-org/lineage-baseline#check

# Import existing policy files
nix run github:Lineage-org/lineage-baseline#import-policy -- --auto

# List supported license types
nix run github:Lineage-org/lineage-baseline#list-licenses

# Fetch license from SPDX
nix run github:Lineage-org/lineage-baseline#fetch-license -- Apache-2.0 --holder "ACME Corp"

# Create a new pack
nix run github:Lineage-org/lineage-baseline#create-pack flake8
```

## Policy Packs

Lineage uses two types of policy packs with different architectural approaches and capabilities:

### Pack Types Overview

**Parameterized Packs** are dynamic, configuration-driven policy generators that adapt their output based on runtime configuration. These packs support organization-specific customization through `.lineage.toml` files and CLI overrides.

**Non-Parameterized Packs** are static policy definitions that provide standardized configurations without customization. These are used for policies that should remain consistent across all repositories without variation.

### Pack Directory Structure

Packs are organized by language ecosystem and type:

```
packs/
├── universal/           # Cross-language parameterized packs
├── python/              # Python ecosystem packs
├── javascript/          # JavaScript/Node.js ecosystem packs
├── rust/                # Rust ecosystem packs (future)
└── go/                  # Go ecosystem packs (future)
```

## Configuration File Reference

### .lineage.toml Structure

Lineage supports configuration-driven customization via `.lineage.toml` files.

```toml
[baseline]
repo = "github:Lineage-org/lineage-baseline"
ref = "stable"

[organization]
name = "MyCompany"
security_email = "security@lineage.run"
default_team = "@MyCompany/maintainers"

[packs]
enabled = ["editorconfig", "codeowners", "security", "license", "precommit"]

[packs.editorconfig]
indent_size = 4
line_length = 100
charset = "utf-8"
end_of_line = "lf"

[packs.editorconfig.languages]
python = { indent_size = 4, max_line_length = 88 }
javascript = { indent_size = 2 }

[packs.codeowners]
rules = [
  { pattern = "*", owners = ["@MyCompany/maintainers"] },
  { pattern = "*.py", owners = ["@MyCompany/python-team"] },
  { pattern = "*.js", owners = ["@MyCompany/frontend-team"] },
  { pattern = "docs/**", owners = ["@MyCompany/docs-team"] }
]

[packs.security]
response_time = "within 24 hours"
disclosure_policy = "coordinated"
supported_versions = [
  { version = "2.x.x", supported = true },
  { version = "1.x.x", supported = false }
]

[packs.license]
type = "MIT"
holder = "MyCompany, Inc."
year = "2024"
# OR use custom file for complete override
custom_file = "my-custom-license.txt"

[packs.precommit]
hooks = ["trailing-whitespace", "black", "flake8", "prettier"]
python_version = "3.11"
black_line_length = 88
```

### Custom File Support

All packs support the `custom_file` parameter for complete content override:

```toml
[packs.license]
custom_file = "my-license.txt"
```

## Customization Checklist

When you fork this baseline for your organization, follow this checklist to customize it for your needs:

### Required Customizations

1.  **License Pack:** Edit `packs/license.nix` or use `custom_file`.
2.  **Security Pack:** Edit `packs/security.nix` with your email.
3.  **Code Owners Pack:** Update `org` variable in `packs/codeowners.nix`.
4.  **Editor Config Pack:** Customize `packs/editorconfig.nix`.
5.  **Dependabot Pack:** Edit `packs/dependabot.nix`.

### Optional Customizations

6.  **Import Existing Policies:** Use `import-policy` app.
