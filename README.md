<p align="center">
  <img src="assets/lineage_banner.png" alt="Lineage — Policy Governance via Nix" width="100%">
</p>

# Lineage Baseline

[![Update Nixpkgs](https://github.com/Lineage-org/lineage-baseline/actions/workflows/update-nixpkgs.yml/badge.svg)](https://github.com/Lineage-org/lineage-baseline/actions/workflows/update-nixpkgs.yml)
[![Promote to Stable](https://github.com/Lineage-org/lineage-baseline/actions/workflows/promote-to-stable.yml/badge.svg)](https://github.com/Lineage-org/lineage-baseline/actions/workflows/promote-to-stable.yml)

**Tags:** [![Unstable](https://img.shields.io/github/v/tag/Lineage-org/lineage-baseline?filter=unstable&label=unstable&color=orange)](https://github.com/Lineage-org/lineage-baseline/releases/tag/unstable) [![Stable](https://img.shields.io/github/v/tag/Lineage-org/lineage-baseline?filter=stable&label=stable&color=green)](https://github.com/Lineage-org/lineage-baseline/releases/tag/stable)

The **Lineage Baseline** defines the foundational Nix expressions and policies used by all repositories in the [Lineage-org](https://github.com/Lineage-org) organization.
It provides the shared Nix logic, governance rules and automation logic that all Lineage consumer repositories rely on.

> **⚠️ Development Status**: Lineage is under active development.
>
> - **For production use**: Pin to the `stable` tag: `github:Lineage-org/lineage-baseline?ref=stable`
> - **For testing/contributing**: Use `unstable` branch or `main`
> - **Breaking changes** may occur in unstable without notice
> - The `stable` tag provides a tested, stable reference point (not semantic versioning)

## Security & Configuration

This baseline provides organization-wide policy management with comprehensive validation. See [SECURITY-BASELINE.md](SECURITY-BASELINE.md) for security best practices and recommended branch protection settings.

## Table of Contents

- [Security Requirements](#security-requirements)
- [What is Lineage?](#what-is-lineage)
  - [Key Benefits](#key-benefits)
  - [Why Lineage?](#why-lineage)
- [Consumption Patterns](#consumption-patterns)
- [Purpose](#purpose)
- [External Pack Development](#external-pack-development)
- [Architecture](#architecture)
- [Workflow Dependencies](#workflow-dependencies)
- [Usage](#usage)
  - [Baseline Apps](#baseline-apps)
  - [Quick Start for Consumer Repos](#quick-start-for-consumer-repos)
- [Policy Packs](#policy-packs)
  - [Organization Script Packs](#organization-script-packs)
- [Configuration File Reference](#configuration-file-reference)
- [Governance Migration](#governance-migration)
  - [Complete Governance Migration](#complete-governance-migration)
  - [Migration Architecture](#migration-architecture)
  - [GitHub Actions Governance Migration](#github-actions-governance-migration)
  - [Import Individual Policy Files](#import-individual-policy-files)
  - [Fetch License from SPDX](#fetch-license-from-spdx)
  - [Testing Governance Migration](#testing-governance-migration)
  - [Demo Repository](#demo-repository)
- [Understanding Pack Propagation](#understanding-pack-propagation)
- [Recommended Implementation](#recommended-implementation)
- [Customization Checklist](#customization-checklist)
- [Tagging Policy](#tagging-policy)
- [Supply Chain Security - Nixpkgs Updates](#supply-chain-security---nixpkgs-updates)
- [Baseline Promotion Workflow](#baseline-promotion-workflow)
- [Stable Candidate Coordination](#stable-candidate-coordination)
- [Lineage vs Traditional Policy Distribution](#lineage-vs-traditional-policy-distribution)
- [Importance of the Baseline](#importance-of-the-baseline)

---

## Security Requirements

### Baseline Repository Best Practices

For production usage:

1. **Enable comprehensive CI validation** - primary security control
2. **Configure branch protection** with required status checks
3. **Use automation-friendly policies** - allow validated workflows to bypass PRs
4. **Enable CODEOWNERS** for human changes requiring review
5. **Use configuration-driven customization** - avoid hard-coding org values

See [SECURITY-BASELINE.md](SECURITY-BASELINE.md) for detailed security guidelines and CI-first best practices.

---

## What is Lineage?

**Lineage** provides organization-wide CI governance and policy enforcement through Nix flakes with **configuration-driven consumption** that eliminates the need for forking or maintaining your own baseline.

### Key Benefits

- **Pure Upstream Consumption**: Use Lineage baseline directly without forking
- **Zero Maintenance Overhead**: Consume as pure upstream, receive improvements automatically
- **Configuration-Driven**: Full customization through `.lineage.toml` files and CLI overrides
- **Governance Migration**: Automatic conversion of existing governance repositories to Lineage format
- **Workflow Automation**: Pre-validated CI/CD workflows with auto-merge support
- **Script Packaging**: Automatic detection and distribution of organization-specific scripts
- **Immediate Updates**: Receive baseline improvements instantly without manual intervention
- **Custom File Support**: Override any pack with organization-specific files
- **Parameterized Packs**: Runtime configuration passing following nix.dev best practices
- **External Pack Support**: Add organization-specific packs via template pattern
- **Reproducible**: All dependencies pinned, configuration separated from logic

### Why Lineage?

**The Problem**: Organizations managing hundreds of repositories face a critical challenge - when security policies change, licenses are adopted or coding standards are updated, those changes must propagate to every repository. Traditional governance systems create individual pull requests to each repository, requiring manual review and merge. For an organization with 500 repositories, a single policy change creates 500 separate pull requests requiring human attention.

**The Solution**: Lineage eliminates the pull request bottleneck through Nix-based materialization. Policies propagate instantly through flake updates while maintaining audit trails through optional PR workflows with auto-merge. Organizations receive:

- **Instant Policy Updates**: Changes materialize immediately without PR bottlenecks
- **Governance Migration**: Convert existing governance repositories automatically
- **Automated Workflows**: Pre-built CI/CD with validation and auto-merge
- **Pure Upstream Consumption**: Zero maintenance overhead, no baseline forking required
- **Flexible Review Controls**: Direct commits for speed or PR workflows for compliance

---

## Consumption Patterns

Lineage offers three consumption patterns to match different organizational needs:

```mermaid
graph TB
    A[Organization Needs Governance] --> B{Configuration Needed?}

    B -->|None| C[Direct Consumption]
    B -->|Organization Branding| D[Configuration-Driven]
    B -->|+ External Packs| E[Template-Based]

    C --> C1[nix run github:Lineage-org/lineage-baseline#sync]
    C --> C2[✅ Zero configuration]
    C --> C3[✅ Default policies only]
    C --> C4[❌ No customization]

    D --> D1[Create .lineage.toml + run sync]
    D --> D2[✅ Organization branding]
    D --> D3[✅ Pack customization]
    D --> D4[✅ Custom file support]
    D --> D5[✅ CLI overrides]
    D --> D6[❌ No external packs]

    E --> E1[nix flake new -t baseline]
    E --> E2[✅ All configuration features]
    E --> E3[✅ External pack support]
    E --> E4[✅ Version pinning]
    E --> E5[❌ Requires local flake.nix]

    style C fill:#f5f5f5
    style D fill:#e1f5fe
    style E fill:#f3e5f5
```

### Pattern 1: Direct Consumption (Default)

**Best for**: Quick start with default Lineage policies.

```bash
# No configuration required - uses defaults
nix run github:Lineage-org/lineage-baseline#sync
```

### Pattern 2: Configuration-Driven (Recommended)

**Best for**: Organizations wanting customization without baseline forking.

```bash
# Create configuration file, then sync
nix run github:Lineage-org/lineage-baseline#sync -- --config .lineage.toml
```

**Configuration-Driven Architecture**:
```mermaid
flowchart LR
    A[.lineage.toml<br/>Organization Config] --> B[Enhanced Sync App]
    C[CLI Overrides<br/>--override org.name=...] --> B
    D[Custom Files<br/>custom-license.txt] --> B

    B --> E[Runtime Config Passing]
    E --> F[Parameterized Packs]
    F --> G[Generated Policy Files<br/>with Org Branding]

    style A fill:#e8f5e8
    style C fill:#d1ecf1
    style D fill:#fff3cd
    style G fill:#FF9800
```

**Example Configuration**:
```toml
# .lineage.toml
[organization]
name = "MyCompany"
security_email = "security@mycompany.com"
default_team = "@MyCompany/maintainers"

[packs]
enabled = ["editorconfig", "license", "codeowners"]

[packs.license]
custom_file = "my-license.txt"

[packs.editorconfig]
indent_size = 4
line_length = 100
```

### Pattern 3: Template-Based (With External Packs)

**Best for**: Organizations needing custom packs while avoiding baseline forking.

```bash
# Initialize from template
nix flake new -t github:Lineage-org/lineage-baseline my-repo
cd my-repo

# Add external packs to flake.nix, then sync
nix run .#sync
```

**Architecture**:
```mermaid
flowchart TD
    A[flake.nix] --> B[External Pack Inputs]
    A --> C[Baseline Input]

    D[.lineage.toml] --> E[Template Sync App]

    B --> F[myorg-security-packs/custom-security]
    C --> G[Built-in Packs]

    E --> H[Combined Pack Registry]
    F --> H
    G --> H

    H --> I[Policy Files]

    style A fill:#e1f5fe
    style D fill:#e8f5e8
    style B fill:#f3e5f5
    style C fill:#fff3cd
```

---

## Purpose

Lineage uses a **hybrid architecture** with two types of governance:

### 1. Persistent Policies (Committed)
Files like `LICENSE`, `SECURITY.md`, `.editorconfig` are materialized and committed to consumer repos for visibility and GitHub integration.

### 2. Pure Nix Apps (No Files)
Apps like pack creation and policy import tools run via `nix run .#app` with no file materialization.

---

## External Pack Development

Organizations can create their own pack repositories to extend Lineage functionality:

### External Pack Repository Structure

```
myorg-lineage-packs/
├── flake.nix
├── lib/
│   └── default.nix      # Pack registry
└── packs/
    ├── golang-standards.nix
    ├── custom-security.nix
    └── compliance-audit.nix
```

### Example External Pack

```nix
# packs/golang-standards.nix
{ pkgs, lib, config ? {} }:

{
  files = {
    ".golangci.yml" = ''
      # Organization-specific Go linting rules
      linters:
        enable:
          - gofmt
          - golint
          - govet
    '';
  };

  checks = [
    {
      name = "golang-format";
      check = ''
        if [[ -f ".golangci.yml" ]]; then
          echo "✓ Go linting configuration present"
        fi
      '';
    }
  ];
}
```

### Using External Packs

1. **Add to flake inputs**:
```nix
inputs.myorg-packs.url = "github:myorg/lineage-packs";
```

2. **Reference in .lineage.toml**:
```toml
[packs]
enabled = [
  "editorconfig",
  "myorg-packs/golang-standards"
]
```

The [lineage-demo1](https://github.com/Lineage-org/lineage-demo1) demonstrates **direct consumption**, while [lineage-demo2](https://github.com/Lineage-org/lineage-demo2) shows **configuration-driven** patterns.

---

## Architecture

### Direct Consumption Pattern (Pure Upstream)

```mermaid
graph LR
    subgraph baseline["&nbsp;&nbsp;&nbsp;&nbsp;Lineage Baseline Repository&nbsp;&nbsp;&nbsp;&nbsp;"]
        B1["&nbsp;&nbsp;flake.nix&nbsp;&nbsp;<br/>&nbsp;<br/>&nbsp;&nbsp;Exposes apps & packs&nbsp;&nbsp;"]
        B2["&nbsp;&nbsp;packs/ (parameterized)&nbsp;&nbsp;<br/>&nbsp;<br/>&nbsp;&nbsp;Built-in Policy Definitions&nbsp;&nbsp;"]
        B3["&nbsp;&nbsp;apps/sync.nix&nbsp;&nbsp;<br/>&nbsp;<br/>&nbsp;&nbsp;Enhanced with TOML support&nbsp;&nbsp;"]
        B4["&nbsp;&nbsp;lib/config.nix&nbsp;&nbsp;<br/>&nbsp;<br/>&nbsp;&nbsp;Configuration Parser&nbsp;&nbsp;"]
        B1 --> B2
        B1 --> B3
        B1 --> B4
    end

    subgraph consumer["&nbsp;&nbsp;&nbsp;&nbsp;Consumer Repository (Direct)&nbsp;&nbsp;&nbsp;&nbsp;"]
        C1["&nbsp;&nbsp;.lineage.toml&nbsp;&nbsp;<br/>&nbsp;<br/>&nbsp;&nbsp;Configuration Only&nbsp;&nbsp;"]
        C2["&nbsp;&nbsp;Policy Files&nbsp;&nbsp;<br/>&nbsp;<br/>&nbsp;&nbsp;LICENSE, SECURITY.md, etc.&nbsp;&nbsp;"]
        C3["&nbsp;&nbsp;Custom Files&nbsp;&nbsp;<br/>&nbsp;<br/>&nbsp;&nbsp;(optional overrides)&nbsp;&nbsp;"]
    end

    C1 -.->|"&nbsp;github:baseline#sync&nbsp;"| B3
    C3 -.->|"&nbsp;custom_file refs&nbsp;"| B3
    B3 -->|"&nbsp;materialized&nbsp;"| C2

    style B1 fill:#4CAF50,color:#000000,stroke:#333,stroke-width:2px
    style B2 fill:#4CAF50,color:#000000,stroke:#333,stroke-width:2px
    style B3 fill:#4CAF50,color:#000000,stroke:#333,stroke-width:2px
    style B4 fill:#4CAF50,color:#000000,stroke:#333,stroke-width:2px
    style C1 fill:#e8f5e8,color:#000000,stroke:#333,stroke-width:2px
    style C2 fill:#FF9800,color:#000000,stroke:#333,stroke-width:2px
    style C3 fill:#fff3cd,color:#000000,stroke:#333,stroke-width:2px
```

### Template Consumption Pattern (With External Packs)

```mermaid
graph TD
    subgraph baseline["&nbsp;&nbsp;&nbsp;&nbsp;Lineage Baseline Repository&nbsp;&nbsp;&nbsp;&nbsp;"]
        B1["&nbsp;&nbsp;flake.nix&nbsp;&nbsp;<br/>&nbsp;<br/>&nbsp;&nbsp;Exposes apps & packs&nbsp;&nbsp;"]
        B2["&nbsp;&nbsp;packs/ (parameterized)&nbsp;&nbsp;<br/>&nbsp;<br/>&nbsp;&nbsp;Built-in Policy Definitions&nbsp;&nbsp;"]
        B3["&nbsp;&nbsp;templates/consumer/&nbsp;&nbsp;<br/>&nbsp;<br/>&nbsp;&nbsp;Template with External Pack Support&nbsp;&nbsp;"]
    end

    subgraph external["&nbsp;&nbsp;&nbsp;&nbsp;External Pack Repository&nbsp;&nbsp;&nbsp;&nbsp;"]
        E1["&nbsp;&nbsp;flake.nix&nbsp;&nbsp;<br/>&nbsp;<br/>&nbsp;&nbsp;Exposes lib.packs&nbsp;&nbsp;"]
        E2["&nbsp;&nbsp;packs/&nbsp;&nbsp;<br/>&nbsp;<br/>&nbsp;&nbsp;Custom Organization Packs&nbsp;&nbsp;"]
    end

    subgraph consumer["&nbsp;&nbsp;&nbsp;&nbsp;Consumer Repository (Template)&nbsp;&nbsp;&nbsp;&nbsp;"]
        C1["&nbsp;&nbsp;flake.nix&nbsp;&nbsp;<br/>&nbsp;<br/>&nbsp;&nbsp;References baseline + external&nbsp;&nbsp;"]
        C2["&nbsp;&nbsp;.lineage.toml&nbsp;&nbsp;<br/>&nbsp;<br/>&nbsp;&nbsp;Pack selection & config&nbsp;&nbsp;"]
        C3["&nbsp;&nbsp;Policy Files&nbsp;&nbsp;<br/>&nbsp;<br/>&nbsp;&nbsp;From built-in + external packs&nbsp;&nbsp;"]
        C4["&nbsp;&nbsp;Template Sync App&nbsp;&nbsp;<br/>&nbsp;<br/>&nbsp;&nbsp;Combines all pack sources&nbsp;&nbsp;"]
    end

    B1 -.->|"&nbsp;flake input&nbsp;"| C1
    E1 -.->|"&nbsp;flake input&nbsp;"| C1
    B3 -.->|"&nbsp;template&nbsp;"| C1

    C1 --> C4
    C2 --> C4
    B2 --> C4
    E2 --> C4
    C4 --> C3

    style B1 fill:#4CAF50,color:#000000,stroke:#333,stroke-width:2px
    style B2 fill:#4CAF50,color:#000000,stroke:#333,stroke-width:2px
    style B3 fill:#4CAF50,color:#000000,stroke:#333,stroke-width:2px
    style E1 fill:#f3e5f5,color:#000000,stroke:#333,stroke-width:2px
    style E2 fill:#f3e5f5,color:#000000,stroke:#333,stroke-width:2px
    style C1 fill:#e1f5fe,color:#000000,stroke:#333,stroke-width:2px
    style C2 fill:#e8f5e8,color:#000000,stroke:#333,stroke-width:2px
    style C3 fill:#FF9800,color:#000000,stroke:#333,stroke-width:2px
    style C4 fill:#d1ecf1,color:#000000,stroke:#333,stroke-width:2px
```

### Repository Types

1. **`.github` Repository** ([Lineage-org/.github](https://github.com/Lineage-org/.github))
   - Contains reusable GitHub Actions workflows
   - Referenced via `uses: YOUR-ORG/.github/.github/workflows/lineage-ci.yml@stable`

2. **Baseline Repository** (this repo)
   - Stores Nix-based policy definitions ("packs")
   - Exposes packs as flake lib outputs
   - Provides migration tools (import-policy, fetch-license)
   - Provides consumer template via `nix flake init -t`
   - Organizations fork this to create their own governance baseline

3. **Consumer Repositories** ([lineage-demo1](https://github.com/Lineage-org/lineage-demo1))
   - Your actual projects
   - Reference baseline as a flake input
   - Run `nix run .#sync` to materialize persistent policies
   - Run utility apps for pack creation and policy import

---

## Workflow Dependencies

The Lineage architecture follows a clean dependency pattern where baseline repositories exclusively use reusable workflows from the `.github` repository, rather than calling GitHub Actions directly.

### Proper Dependency Architecture

```mermaid
graph TD
    subgraph "Lineage Organization"
        subgraph ".github Repository"
            A[Reusable Workflows]
            A1[lineage-ci.yml]
            A2[lineage-promote-to-stable.yml]
            A3[lineage-branch-validation.yml]
            A4[lineage-policy-sync.yml]
            A --> A1
            A --> A2
            A --> A3
            A --> A4
        end

        subgraph "Baseline Repository"
            B[Caller Workflows]
            B1[ci.yml]
            B2[promote-to-stable.yml]
            B3[update-nixpkgs.yml]
            B --> B1
            B --> B2
            B --> B3
        end

        subgraph "GitHub Actions Marketplace"
            C[Actions]
            C1[actions/checkout@v4]
            C2[cachix/install-nix-action@v31]
            C3[github-script@v7]
            C --> C1
            C --> C2
            C --> C3
        end
    end

    B1 -.->|uses| A1
    B2 -.->|uses| A2
    B3 -.->|uses| A2

    A1 -.->|uses| C1
    A1 -.->|uses| C2
    A2 -.->|uses| C1
    A2 -.->|uses| C2
    A3 -.->|uses| C1
    A3 -.->|uses| C3

    style A fill:#4CAF50,color:#000000,stroke:#333,stroke-width:2px
    style B fill:#2196F3,color:#ffffff,stroke:#333,stroke-width:2px
    style C fill:#FF9800,color:#000000,stroke:#333,stroke-width:2px
```

### Why This Pattern Matters

**Centralized Maintenance:**
- All GitHub Action versions managed in one place (`.github` repo)
- Dependency updates only need to happen once
- Security patches propagate automatically to all repositories

**Clean Separation:**
- Baseline repositories only know about `.github` workflows
- No direct coupling to external GitHub Actions
- Easier to audit and manage dependencies

**Consistent Patterns:**
- Same approach across all Lineage repositories
- Predictable workflow structure
- Better developer experience

### Implementation Status

Current baseline workflows should only call reusable workflows:

[+] **Correct Pattern:**
```yaml
jobs:
  ci:
    uses: Lineage-org/.github/.github/workflows/lineage-ci.yml@stable
```

[-] **Avoid Direct Action Calls:**
```yaml
steps:
  - uses: actions/checkout@v4
  - uses: cachix/install-nix-action@v31
```

Organizations forking Lineage should maintain this pattern by:
1. Forking both `.github` and `lineage-baseline` repositories
2. Updating workflow references to point to their organization
3. Never calling actions directly from baseline workflows

---

## Usage

### Enhanced Sync App

The sync app now features **runtime configuration passing** following nix.dev best practices, enabling organizations to consume the baseline as pure upstream without forking.

**Basic Usage:**
```bash
# Default policies (no configuration)
nix run github:Lineage-org/lineage-baseline#sync

# Configuration-driven (organization branding)
nix run github:Lineage-org/lineage-baseline#sync -- --config .lineage.toml

# Preview changes without applying
nix run github:Lineage-org/lineage-baseline#sync -- --dry-run

# Select specific packs
nix run github:Lineage-org/lineage-baseline#sync -- --packs editorconfig,license,codeowners

# Exclude packs from defaults
nix run github:Lineage-org/lineage-baseline#sync -- --exclude security,dependabot

# CLI overrides (runtime customization)
nix run github:Lineage-org/lineage-baseline#sync -- --override org.name=MyCompany
nix run github:Lineage-org/lineage-baseline#sync -- --override org.email=security@mycompany.com

# Combine options
nix run github:Lineage-org/lineage-baseline#sync -- --config .lineage.toml --override org.name=TestCorp --dry-run
```

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

**Template-based (after `nix flake init -t`):**
```bash
# Materialize persistent policies
nix run .#sync

# Validate policies match baseline
nix run .#check

# Additional utility apps available
nix run .#create-pack <name>
nix run .#import-policy -- --auto
nix run .#fetch-license -- Apache-2.0 --holder "My Company"
```

### Quick Start for Consumer Repos

Choose from three consumption patterns:

#### Option 1: Direct Consumption (Default Policies)

For quick start with default Lineage policies:

```bash
# Sync default policies
nix run github:Lineage-org/lineage-baseline#sync

# Verify policies are in sync
nix run github:Lineage-org/lineage-baseline#check

# Commit the materialized policy files
git add LICENSE SECURITY.md .editorconfig .github/
git commit -m "add Lineage policies"
```

**Customize packs with command line arguments:**
```bash
# Include only specific packs
nix run github:Lineage-org/lineage-baseline#sync -- --packs editorconfig,license,codeowners

# Exclude specific packs from defaults
nix run github:Lineage-org/lineage-baseline#sync -- --exclude security,dependabot

# Check only specific packs
nix run github:Lineage-org/lineage-baseline#check -- --packs editorconfig,license
```

**Or use environment variable (fallback):**
```bash
# Environment variable approach
LINEAGE_PACKS="editorconfig,license,dependabot" nix run github:Lineage-org/lineage-baseline#sync
```

### CI Architecture: Baseline vs Consumer Repositories

**IMPORTANT:** Baseline and consumer repositories require different CI approaches:

#### Baseline Repository CI (this repo)
Validates the source repository itself - flake integrity, apps, and pack definitions:

```yaml
# .github/workflows/ci.yml (baseline repos only)
name: Baseline CI
on: [push, pull_request]
jobs:
  validate-baseline:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - uses: cachix/install-nix-action@v31
      - name: Validate flake integrity
        run: nix flake check
      - name: Test apps (dry-run only)
        run: |
          nix run .#sync -- --dry-run
          nix run .#list-licenses
```

**Key Points:**
- [+] Tests flake and apps work correctly
- [+] Uses dry-run mode (no file materialization)
- [-] Does NOT use lineage-ci.yml reusable workflow
- [-] Does NOT materialize policy files into itself

#### Consumer Repository CI
Materializes and validates files FROM the baseline:

```yaml
# .github/workflows/ci.yml (consumer repos only)
name: CI
on: [push, pull_request]
jobs:
  policy-check:
    uses: YOUR-ORG/.github/.github/workflows/lineage-ci.yml@stable
    with:
      channel: stable
      packs: "editorconfig,codeowners,license,precommit"
```

**Key Points:**
- [+] Uses lineage-ci.yml reusable workflow
- [+] Materializes files from baseline and validates them
- [+] Tests consumer repository compliance
- [-] NOT suitable for baseline repositories

#### Why This Distinction Matters

**Baseline repositories** are the SOURCE of policy definitions. They should validate that:
- Flake expressions are valid
- Apps work correctly (in dry-run mode)
- Pack definitions are syntactically correct

**Consumer repositories** CONSUME policies from the baseline. They should validate that:
- Materialized files match baseline expectations
- Local policies comply with organizational standards
- All required files are present and correct

See [lineage-demo1](https://github.com/Lineage-org/lineage-demo1) for a complete example.

#### Option 2: Configuration-Driven (Recommended)

For organizations wanting customization without baseline forking:

**Create configuration file:**
```toml
# .lineage.toml
[organization]
name = "MyCompany"
security_email = "security@mycompany.com"
default_team = "@MyCompany/maintainers"

[packs]
enabled = ["editorconfig", "codeowners", "security", "license"]

[packs.codeowners]
rules = [
  { pattern = "*", owners = ["@MyCompany/maintainers"] },
  { pattern = "*.py", owners = ["@MyCompany/python-team"] }
]

[packs.editorconfig]
indent_size = 4
line_length = 100
```

**Sync with configuration:**
```bash
# Use configuration file
nix run github:Lineage-org/lineage-baseline#sync

# Preview changes
nix run github:Lineage-org/lineage-baseline#sync -- --dry-run

# Override specific values
nix run github:Lineage-org/lineage-baseline#sync -- --override org.name=AnotherCompany

# Use custom config file
nix run github:Lineage-org/lineage-baseline#sync -- --config my-config.toml
```

**Generated files will include:**
- Organization branding (MyCompany in CODEOWNERS, security email in SECURITY.md)
- Custom pack selection (only specified packs materialized)
- Pack-specific customization (custom indentation, team ownership rules)

**Benefits:**
- No baseline forking required
- Organization-specific customization
- Instant updates from upstream baseline
- Configuration-driven policy inheritance
- Runtime configuration passing to parameterized packs
- Custom file support for complete override capability

**Technical Implementation:**
The enhanced sync app follows nix.dev best practices by:
- Separating configuration (JSON) from logic (Nix expressions)
- Using `nix eval` for runtime configuration passing
- Maintaining reproducibility through explicit dependencies
- Supporting both TOML configuration and CLI overrides

See [lineage-demo2](https://github.com/Lineage-org/lineage-demo2) for a complete example.

#### Option 3: Template-Based (Full Featured)

For organizations that need local flake customization and additional apps:

```bash
# Initialize from template
nix flake init -t github:Lineage-org/lineage-baseline
```

This copies files from the baseline's `templates/consumer/` directory into your current directory, giving you a ready-to-use consumer repository.

**What you get:**

- `flake.nix` - Consumer flake that references the baseline as an input and exposes sync/check apps
- `.github/workflows/policy-sync.yml` - Automated weekly policy sync workflow
- `.pre-commit-config.yaml` - Pre-commit hooks configuration
- `.gitignore` - Standard ignores for Nix projects
- `flake.lock` - Pinned dependencies

**Important:** The consumer repository's `flake.nix` is different from the baseline repository's `flake.nix`:

- **Baseline `flake.nix`** (this repo) - Exposes the packs library and utility apps for all consumers
- **Consumer `flake.nix`** (from template) - Configures which packs to use and implements sync/check for that specific repo

**Customize enabled packs:**

Edit the `persistentPacks` list in your consumer repository's `flake.nix` (not the baseline):

```nix
# Select which packs to enable
persistentPacks = [
  "editorconfig"   # Code formatting standards
  "license"        # Repository license
  "security"       # Security policy
  "codeowners"     # Code ownership rules
  "dependabot"     # Dependabot configuration
];
```

This list controls which policy files are materialized into your repository when running `nix run .#sync`. The consumer template includes this configuration by default. See [`templates/consumer/flake.nix`](./templates/consumer/flake.nix) for the full implementation.

**First-time setup:**

After initializing a consumer repository, you must sync the policy files:

```bash
# Materialize policy files from baseline
nix run .#sync

# Verify policies are in sync
nix run .#check

# Commit the materialized policy files
git add LICENSE SECURITY.md .editorconfig .github/CODEOWNERS .github/dependabot.yml
git commit -m "add Lineage policies"
```

**Important:** CI will fail until you run `nix run .#sync` and commit the policy files. This is expected behavior for new consumer repositories.

**Available apps:**

```bash
# Check policies match baseline
nix run .#check

# Sync policies from baseline
nix run .#sync

# Create new policy pack
nix run .#create-pack <name>

# Import existing policies
nix run .#import-policy -- --auto

# Fetch license from SPDX
nix run .#fetch-license -- Apache-2.0 --holder "My Company"
```

The policy sync workflow runs automatically weekly on Sunday at 2 PM UTC, checking for baseline updates and committing any changes.

---

## Policy Packs

Lineage uses two types of policy packs with different architectural approaches and capabilities:

### Pack Types Overview

**Parameterized Packs** are dynamic, configuration-driven policy generators that adapt their output based on runtime configuration. These packs support organization-specific customization through `.lineage.toml` files and CLI overrides.

**Non-Parameterized Packs** are static policy definitions that provide standardized configurations without customization. These are used for policies that should remain consistent across all repositories without variation.

### Parameterized vs Non-Parameterized Architecture

```mermaid
graph TB
    subgraph "Parameterized Packs"
        A1[.lineage.toml Configuration] --> B1[Runtime Config Passing]
        B1 --> C1[Dynamic Policy Generation]
        C1 --> D1[Organization-Branded Files]

        style A1 fill:#e8f5e8
        style D1 fill:#4CAF50
    end

    subgraph "Non-Parameterized Packs"
        A2[Static Nix Expression] --> B2[Fixed Content]
        B2 --> C2[Standardized Files]

        style A2 fill:#f5f5f5
        style C2 fill:#9E9E9E
    end
```

### Organized Pack Directory Structure

Packs are organized by language ecosystem and type:

```
packs/
├── universal/           # Cross-language parameterized packs
│   ├── license-parameterized.nix
│   ├── codeowners-parameterized.nix
│   ├── security-parameterized.nix
│   ├── editorconfig-parameterized.nix
│   ├── precommit-parameterized.nix
│   ├── dependabot-parameterized.nix
│   ├── gitignore-parameterized.nix
│   ├── prettier-parameterized.nix
│   └── yamllint-parameterized.nix
├── python/              # Python ecosystem packs
│   ├── bandit.nix              # Non-parameterized security rules
│   └── flake8-parameterized.nix # Parameterized linting config
├── javascript/          # JavaScript/Node.js ecosystem packs
│   ├── eslint-parameterized.nix # Parameterized linting config
│   └── jest-parameterized.nix   # Parameterized testing config
├── rust/                # Rust ecosystem packs (future)
└── go/                  # Go ecosystem packs (future)
```

### When to Use Each Type

**Use Parameterized Packs When:**
- Organizations need branding customization (names, emails, teams)
- Configuration varies between organizations (coding standards, policies)
- Multiple valid approaches exist (license types, formatting preferences)
- Organizations want to maintain consistency while allowing flexibility

**Use Non-Parameterized Packs When:**
- Security scanning rules should be standardized without variation
- Compliance requirements mandate specific configurations
- Best practices are universal and should not be customized
- Simplicity is preferred over flexibility

### Example: Parameterized Pack

```nix
# packs/universal/license-parameterized.nix
{ pkgs, lib, config ? {} }:

let
  licenseType = config.packs.license.type or "Apache-2.0";
  copyrightHolder = config.organization.name or "CHANGEME";
  copyrightYear = config.packs.license.year or "2025";
in {
  files = {
    "LICENSE" = ''
      Copyright ${copyrightYear} ${copyrightHolder}

      Licensed under the ${licenseType} License...
    '';
  };

  meta = {
    description = "Configurable license with organization branding";
    parameterized = true;
  };
}
```

**Configuration (`.lineage.toml`):**
```toml
[organization]
name = "ACME Corp"

[packs.license]
type = "MIT"
year = "2024"
```

### Example: Non-Parameterized Pack

```nix
# packs/python/bandit.nix
{ pkgs, lib, config ? {} }:

{
  files = {
    ".bandit" = ''
      [bandit]
      # Standardized Python security scanning configuration
      exclude_dirs = ["tests", "test", ".tox", ".venv"]
      skips = ["B101"]  # Skip assert_used test

      [bandit.any_other_function_with_shell_equals_true]
      no_shell = [
        "subprocess.run",
        "subprocess.call",
        "subprocess.Popen"
      ]
    '';
  };

  checks = [
    {
      name = "bandit-security-scan";
      check = ''
        if command -v bandit >/dev/null 2>&1; then
          bandit -c .bandit -r .
        fi
      '';
    }
  ];

  meta = {
    description = "Standardized Python security scanning rules";
    parameterized = false;
  };
}
```

### Organization Script Packs

**Organization Script Packs** are a special type of pack that provides the distribution mechanism for organization-specific scripts and tooling. During governance migration, Lineage detects executable scripts and common tool files in the governance repository and automatically creates script packs for them.

#### The "Delivery Mechanism" Concept

Script packs serve as the **delivery mechanism** that enables organization-specific scripts to be consistently distributed across all consumer repositories. While the scripts themselves remain intact (not converted to Nix), the pack provides the infrastructure to:

- **Distribute scripts** across all consumer repositories via `nix run baseline#sync`
- **Preserve permissions** ensuring executable scripts maintain their `755` permissions
- **Validate deployment** checking that scripts are present and properly configured
- **Track provenance** documenting where scripts originated during migration
- **Enable customization** allowing per-organization script deployment configuration

#### Script Detection During Migration

The governance migration process automatically detects:

- **Executable files** in the repository root (e.g., `bump-version`, `setup-env`)
- **Script extensions** (.sh, .py, .pl, .rb, .js) in root and subdirectories
- **Script directories** common locations like `scripts/`, `bin/`, `tools/`

#### Generated Script Pack Structure

```nix
# packs/script-bump-version.nix
{ pkgs, lib }:

{
  files = {
    "bump-version" = '''
      #!/bin/bash
      # Original script content preserved exactly
      set -euo pipefail
      # ... rest of script ...
    ''';
  };

  # Preserve executable permissions from original
  permissions = {
    "bump-version" = "755";
  };

  checks = [
    {
      name = "script-bump-version-present";
      check = '''
        if [[ -f "bump-version" ]]; then
          echo "[✓] Organization script bump-version present"
          if [[ ! -x "bump-version" ]]; then
            echo "[!] Warning: bump-version should be executable"
          fi
        else
          echo "[✗] Organization script bump-version missing"
          exit 1
        fi
      ''';
    }
  ];
}
```

#### Why Not Just Copy Files Directly?

Script packs might seem like overhead since scripts remain unchanged, but they provide essential infrastructure:

| Aspect | Without Packs | With Script Packs |
|--------|---------------|-------------------|
| **Distribution** | Manual copying required | Automatic via `nix run baseline#sync` |
| **Validation** | No verification scripts deployed | Automated checks for presence/permissions |
| **Integration** | Outside Lineage ecosystem | Full integration with policy workflow |
| **Customization** | No deployment control | Pack-level configuration possible |
| **Consistency** | Ad-hoc script management | Standardized deployment mechanism |

#### Example: Organization Scripts

When migrating a governance repository with organization-specific tooling, Lineage detects and creates packs for scripts like:

- `bump-version` → `script-bump-version.nix`
- `setup-env` → `script-setup-env.nix`
- `deploy.sh` → `script-deploy.nix`

Consumer repositories then receive these scripts via the standard sync process, ensuring organization tooling is available across all repositories.

### Persistent Packs (Committed to Repos)

These packs materialize files that should be committed for visibility and GitHub integration:

| Pack | Purpose | Files Materialized |
|------|---------|-------------------|
| `editorconfig` | Code formatting standards | `.editorconfig` |
| `license` | Apache 2.0 license | `LICENSE` |
| `security` | Security policy and reporting | `SECURITY.md` |
| `codeowners` | Code ownership and review rules | `.github/CODEOWNERS` |
| `dependabot` | Dependabot configuration | `.github/dependabot.yml` |
| `precommit` | Pre-commit hooks configuration | `.pre-commit-config.yaml` |

### Example Packs (Reference Implementations)

The [`examples/packs/`](examples/packs/) directory contains language-specific pack examples that demonstrate how to create custom packs:

| Pack | Purpose | File Materialized |
|------|---------|-------------------|
| `black` | Python Black formatter config | `pyproject.toml` (Black section) |
| `flake8` | Python Flake8 linter config | `.flake8` |
| `pytest` | Python pytest config | `pytest.ini` |
| `yamllint` | YAML linting config | `.yamllint` |
| `prettierignore` | Prettier ignore patterns | `.prettierignore` |

These are not included in the default pack registry but serve as reference implementations for creating organization-specific packs. See [Creating New Packs](#creating-new-packs) for how to use them.

### Pure Apps (No File Materialization)

These run as Nix apps. Usage depends on consumption pattern:

| App | Purpose | Direct Consumption | Template-Based |
|-----|---------|-------------------|----------------|
| `sync` | Materialize persistent policies | `nix run github:ORG/lineage-baseline#sync` | `nix run .#sync` |
| `check` | Validate policies match baseline | `nix run github:ORG/lineage-baseline#check` | `nix run .#check` |
| `migrate-governance` | Migrate governance repository to baseline (URL or path) | `nix run github:ORG/lineage-baseline#migrate-governance` | `nix run .#migrate-governance` |
| `extract-config` | Extract config from files to generate .lineage.toml | `nix run github:ORG/lineage-baseline#extract-config` | `nix run .#extract-config` |
| `create-pack` | Create new policy pack template | `nix run github:ORG/lineage-baseline#create-pack <name>` | `nix run .#create-pack <name>` |
| `import-policy` | Import individual policy files | `nix run github:ORG/lineage-baseline#import-policy` | `nix run .#import-policy` |
| `fetch-license` | Fetch license from SPDX | `nix run github:ORG/lineage-baseline#fetch-license` | `nix run .#fetch-license` |

### Creating New Packs

**Use example packs as starting point:**

The [`examples/packs/`](examples/packs/) directory contains reference implementations for language-specific packs (black, flake8, pytest, yamllint, prettierignore). Copy these to your forked baseline's `packs/` directory and add them to `lib/packs.nix`.

**Or create from scratch using the pack creation app:**

```bash
# Create a new pack with template (direct consumption)
nix run github:Lineage-org/lineage-baseline#create-pack mypack

# Or if using template-based approach
nix run .#create-pack mypack

# List example pack ideas
nix run github:Lineage-org/lineage-baseline#create-pack -- --list-examples
```

This generates `packs/mypack.nix` with a template structure. Edit the file to define your pack files and configuration:

```nix
{ pkgs, lib, config ? {} }:  # config parameter enables parameterization via .lineage.toml

{
  # Define files to materialize in consumer repositories
  files = {
    "mypack.conf" = ''  # File created at repository root when synced
      # Your pack configuration here
      setting = value
    '';
  };

  # Define validation checks to ensure files are properly synced
  checks = [
    {
      name = "mypack-config-present";
      check = ''
        if [[ -f "mypack.conf" ]]; then
          echo "[PASS] MyPack configuration present"
        else
          echo "[FAIL] MyPack configuration missing"
          exit 1
        fi
      '';
    }
  ];
}
```

**When synced, this creates `mypack.conf` at the repository root:**

```bash
# mypack.conf
# Your pack configuration here
setting = value
```

**Add to baseline:**

For custom packs in your forked baseline, add them to `lib/packs.nix`:

```nix
packModules = {
  # ... existing packs ...
  mypack = import ../packs/mypack.nix { inherit pkgs lib config; };
};
```

**Use in consumer repositories:**

```bash
# Direct consumption with pack selection
nix run github:YOUR-ORG/lineage-baseline#sync -- --packs editorconfig,license,mypack

# Or with .lineage.toml
# [packs]
# enabled = ["editorconfig", "license", "mypack"]

nix run github:YOUR-ORG/lineage-baseline#sync
```

The pack will now be included in automated policy sync across all consumer repositories that enable it.

---

## Configuration File Reference

### .lineage.toml Structure

Lineage supports configuration-driven customization via `.lineage.toml` files. This enables organization-specific branding and policy customization without forking the baseline.

Configuration parsing is handled by [`lib/config.nix`](./lib/config.nix) which supports TOML loading, parameter validation and CLI override integration.

```toml
[baseline]
repo = "github:Lineage-org/lineage-baseline"
ref = "stable"

[organization]
name = "MyCompany"
security_email = "security@mycompany.com"
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

### Configuration Sections

#### `[baseline]`
- `repo`: GitHub repository URL for the baseline
- `ref`: Git reference to use (stable, main, or specific tag)

#### `[organization]`
- `name`: Organization name used in CODEOWNERS and documentation
- `security_email`: Contact email for security vulnerabilities
- `default_team`: Default team for code ownership

#### `[packs]`
- `enabled`: Array of pack names to materialize

#### Pack-Specific Sections

Each pack can have its own configuration section:

**`[packs.editorconfig]`**
- `indent_size`: Default indentation size
- `line_length`: Maximum line length
- `charset`: Character encoding
- `end_of_line`: Line ending style
- `languages`: Language-specific overrides

**`[packs.codeowners]`**
- `rules`: Array of ownership rules with pattern and owners

**`[packs.security]`**
- `response_time`: Expected response time for vulnerabilities
- `disclosure_policy`: Disclosure approach (coordinated, immediate)
- `supported_versions`: Version support matrix

**`[packs.license]`**
- `type`: License type (MIT, Apache-2.0, etc.)
- `holder`: Copyright holder
- `year`: Copyright year
- `custom_file`: Path to custom license file (overrides generated content)

**`[packs.precommit]`**
- `hooks`: Array of pre-commit hooks to enable
- `python_version`: Python version for Python hooks
- `black_line_length`: Line length for Black formatter

### CLI Options

Override configuration values at runtime:

```bash
# Override organization settings
nix run .#sync -- --override org.name=AnotherCompany
nix run .#sync -- --override org.security_email=sec@other.com

# Use custom config file
nix run .#sync -- --config production.toml

# Preview changes without applying
nix run .#sync -- --dry-run

# Combine options
nix run .#sync -- --config .lineage.toml --override org.name=TestCorp --dry-run
```

### Custom File Support

All packs support the `custom_file` parameter for complete content override:

```toml
[packs.license]
custom_file = "my-license.txt"

[packs.security]
custom_file = "our-security-policy.md"

[packs.editorconfig]
custom_file = "team-editorconfig"
```

**How it works:**
1. Create your custom file in the repository root
2. Reference it in `.lineage.toml` using `custom_file`
3. Run sync - your file content replaces the generated pack content
4. Organization templating still works (${ORG_NAME} substitution)

**Example custom license:**
```txt
# my-license.txt
Proprietary License

Copyright (c) 2024 ${ORG_NAME}

This software is proprietary and confidential.
Unauthorized copying is strictly prohibited.
```

Custom files enable complete override capability while maintaining the benefits of configuration-driven consumption.

See [`examples/lineage.toml`](./examples/lineage.toml) for a complete configuration example.

---

## Governance Migration

Organizations can migrate their existing governance repositories to create custom Lineage baselines automatically using Nix's deterministic fetching capabilities.

### Complete Governance Migration

**Migrate entire governance repository:**

```bash
nix run github:Lineage-org/lineage-baseline#migrate-governance -- \
  --governance-repo https://github.com/yourorg/governance \
  --org-name "Your Organization" \
  --org-email "admin@yourorg.com" \
  --security-email "security@yourorg.com"
```

This will fetch the governance repository using Nix's deterministic fetchGit, analyze it for languages and existing policies, generate appropriate .lineage.toml configuration, import supported governance files as Lineage packs and create a complete baseline directory structure ready for deployment.

### Migration Architecture

The governance migration uses a **Nix-idiomatic approach** for repository fetching:

**URL Input Processing:**
- URLs are fetched using `builtins.fetchGit` for deterministic, cached access
- Commit hashes are automatically pinned for reproducibility
- Nix store caching improves performance on repeated runs
- Works with public and private repositories (with appropriate credentials)

**Local Path Support:**
- Local directories are accessed directly for development workflows
- Useful for testing modifications before pushing to remote repositories

**Benefits:**
- **Deterministic**: Same URL always produces same commit hash
- **Cached**: Nix store eliminates redundant downloads
- **Reproducible**: Migration results are consistent across environments
- **Pure**: No external git commands or temporary file handling

**For dry-run analysis:**

```bash
nix run github:Lineage-org/lineage-baseline#migrate-governance -- \
  --governance-repo https://github.com/yourorg/governance \
  --org-name "Your Organization" \
  --dry-run
```

### GitHub Actions Governance Migration

Use the reusable workflow to automate governance migration in CI:

```yaml
# .github/workflows/migrate-to-lineage.yml
name: Migrate to Lineage

on:
  workflow_dispatch:
    inputs:
      organization-name:
        description: 'Organization name'
        required: true
        type: string
      organization-email:
        description: 'Organization contact email'
        required: true
        type: string

jobs:
  migrate:
    uses: Lineage-org/.github/.github/workflows/migrate-governance.yml@stable
    with:
      governance-repo: ${{ github.server_url }}/${{ github.repository }}
      organization-name: ${{ inputs.organization-name }}
      organization-email: ${{ inputs.organization-email }}
      output-mode: 'artifact'
```

This workflow uses Nix's deterministic fetchGit to analyze your repository for governance files and project languages, generate a complete Lineage baseline with organization-specific configuration, create downloadable artifacts with the generated baseline and provide migration reports with next-step instructions.

### Import Individual Policy Files

**Auto-import all recognized files:**

```bash
nix run github:Lineage-org/lineage-baseline#import-policy -- --auto
```

**Import specific file:**

```bash
nix run github:Lineage-org/lineage-baseline#import-policy -- --file .editorconfig
```

**Supported policy files:**
- `.editorconfig` → editorconfig pack
- `LICENSE` → license pack (or use fetch-license)
- `SECURITY.md` → security pack
- `.github/CODEOWNERS` → codeowners pack
- `.github/dependabot.yml` → dependabot pack

### Fetch License from SPDX

**Fetch Apache 2.0 license:**

```bash
nix run github:Lineage-org/lineage-baseline#fetch-license -- Apache-2.0 --holder "My Company" --year 2025
```

**Fetch MIT license:**

```bash
nix run github:Lineage-org/lineage-baseline#fetch-license -- MIT --holder "ACME Corp"
```

**List common licenses:**

```bash
nix run github:Lineage-org/lineage-baseline#fetch-license -- --list
```

The import and fetch tools will:
1. Read your existing file or fetch from SPDX
2. Generate properly formatted pack files in `packs/`
3. Preserve your content while making it Nix-compatible

After importing, you can customize the generated packs and commit them to your forked baseline.

### Testing Governance Migration

Before migrating your organization's governance, test the process:

#### Pre-Migration Testing
```bash
# Test migration compatibility (dry-run)
nix run github:Lineage-org/lineage-baseline#migrate-governance -- \
  --governance-repo https://github.com/yourorg/governance \
  --org-name "Your Organization" \
  --org-email "admin@yourorg.com" \
  --dry-run --verbose
```

#### Add Test Workflow to Governance Repository
Add this workflow to your governance repository to test migration readiness:

```yaml
# .github/workflows/test-lineage-migration.yml
name: Test Lineage Governance Migration

on:
  workflow_dispatch:
    inputs:
      organization-name:
        description: 'Organization name for testing'
        required: true
        type: string

jobs:
  test-migration:
    uses: Lineage-org/.github/.github/workflows/test-governance-migration.yml@stable
    with:
      organization-name: ${{ inputs.organization-name }}
      organization-email: "test@example.com"
      dry-run-only: true
```

**How it works:** This workflow tests migration compatibility of the **current repository** (the governance repository containing the workflow). The reusable workflow automatically uses the checked-out repository as the governance source.

**Test Workflow Architecture:**
```mermaid
flowchart TD
    A[Governance Repository] --> B[Add test-lineage-migration.yml]
    B --> C[Run Workflow Manually]
    C --> D[GitHub Actions Checkout]
    D --> E[Lineage Migration Analysis]

    E --> F{Analysis Results}
    F -->|Success| G[✓ Compatible - Ready for Migration]
    F -->|Warnings| H[⚠ Minor Issues - Review Logs]
    F -->|Errors| I[✗ Incompatible - Fix Issues]

    G --> J[Proceed with Actual Migration]
    H --> K[Review and Fix Warnings]
    I --> L[Fix Errors and Re-test]

    K --> C
    L --> C

    style A fill:#e1f5fe
    style D fill:#f3e5f5
    style E fill:#fff3cd
    style G fill:#c8e6c9
    style H fill:#fff8e1
    style I fill:#ffcdd2
```

#### Expected Test Results
Successful tests complete dry-runs with detected languages and governance files. Warnings about binary files or permission issues are acceptable. Errors about invalid configuration or missing required files must be fixed before migration.

#### Edge Case Testing
The migration tool gracefully handles empty repositories by creating universal packs only, skips binary files with warnings, provides clear error messages for permission issues and handles malformed config files without failing.

See the [test-governance-migration.yml reusable workflow](https://github.com/Lineage-org/.github/blob/main/.github/workflows/test-governance-migration.yml) for a complete test workflow implementation.

### Demo Repository

A demonstration repository will be available to showcase governance migration results. Organizations can browse the generated baseline to see migration results and use it as a template for their own implementations.

---

## Understanding Pack Propagation

**How it works:**

1. You edit a pack file in your forked baseline (e.g., `packs/license.nix`)
2. You commit and push to your baseline repo
3. You re-tag `stable` in your baseline repo
4. **All consumer repos automatically get the updated file on their next sync**

No pull requests for baseline changes. No manual updates. No drift.

This is the key difference from traditional policy distribution systems that use automated pull requests - changes propagate instantly through flake updates instead of requiring PR reviews.

### Automated Policy Sync

Lineage provides two policy sync workflows to match different organizational governance requirements:

#### Option 1: Direct Commit (Default - Maximum Automation)

Consumer repositories can enable automated policy synchronization that commits directly to main:

```yaml
# .github/workflows/policy-sync.yml
name: Policy Sync

on:
  schedule:
    - cron: '0 14 * * 0'  # Weekly on Sunday at 2 PM UTC
  workflow_dispatch:

permissions:
  contents: write
  issues: write

jobs:
  sync:
    uses: YOUR-ORG/.github/.github/workflows/lineage-policy-sync.yml@stable
    with:
      consumption_pattern: direct
      baseline_repo: YOUR-ORG/lineage-baseline
      baseline_ref: stable
```

**How it works:**

1. Weekly cron triggers the workflow
2. Runs `nix run github:ORG/baseline#check` to validate policies
3. If out of sync, runs `nix run github:ORG/baseline#sync` to materialize files
4. **Automatically commits and pushes changes directly to main**
5. Creates issue if sync or push fails

**This eliminates the 500-repo PR bottleneck** - when baseline changes are reviewed once, they propagate automatically to all consumer repos without requiring 500 manual PR reviews.

**Use when:**
- You want maximum automation
- Baseline changes are already reviewed before propagation
- Organization trusts automated policy updates
- No branch protection requiring PRs

#### Option 2: PR with Auto-Approval (Governance + Automation)

For organizations requiring review trails while maintaining automation:

```yaml
# .github/workflows/policy-sync.yml
name: Policy Sync

on:
  schedule:
    - cron: '0 14 * * 0'
  workflow_dispatch:

permissions:
  contents: write
  issues: write
  pull-requests: write

jobs:
  sync:
    uses: YOUR-ORG/.github/.github/workflows/lineage-policy-sync-pr.yml@stable
    with:
      consumption_pattern: direct
      baseline_repo: YOUR-ORG/lineage-baseline
      baseline_ref: stable
      create_pr: true
      auto_approve: true
```

**How it works:**

1. Creates PR with policy changes instead of direct commit
2. Auto-approval workflow approves policy-sync PRs after validation
3. GitHub auto-merge merges PR when CI passes
4. Maintains audit trail while eliminating manual work

**Required: Add auto-approval workflow**

```yaml
# .github/workflows/auto-approve.yml
name: Auto Approve Policy Updates

on:
  pull_request:
    types: [opened, synchronize]

permissions:
  pull-requests: write
  contents: write

jobs:
  auto-approve:
    uses: YOUR-ORG/.github/.github/workflows/lineage-auto-approve.yml@stable
    with:
      pr_title_pattern: "Policy Sync"
      actor_filter: "github-actions[bot]"
      merge_method: "squash"
      enable_auto_merge: true
      require_checks: true
```

**Why auto-approval is safe:**

- Baseline changes are reviewed during PR to baseline repo
- Sync validation ensures policies are correct before creating PR
- CI checks validate materialized files before auto-merge
- Only policy-sync PRs from github-actions bot are auto-approved
- Full audit trail maintained through PR history

**Use when:**
- Organization requires PR audit trails for compliance
- Branch protection rules mandate PRs
- Security team needs review gate option
- Want automation with governance controls

#### Choosing the Right Pattern

| Aspect | Direct Commit | PR with Auto-Approval |
|--------|---------------|----------------------|
| **Automation Level** | Maximum | High (with controls) |
| **Speed** | Instant | Minutes (waits for CI) |
| **Audit Trail** | Commit history | PR + commit history |
| **Governance** | Trust-based | Controlled automation |
| **Review Points** | 1 (at baseline) | 2 (baseline + auto-approve) |
| **Branch Protection** | Not compatible | Required |
| **Best For** | Small/medium orgs | Enterprise orgs |

Both patterns solve the 500-repo bottleneck by eliminating manual PR reviews across consumer repos. The difference is whether you want pure automation or controlled automation with audit trails.

#### Option 3: Smart Unified Workflow (NEW - Recommended)

The smart workflow combines both approaches with intelligent fallback:

```yaml
# .github/workflows/policy-sync.yml
name: Policy Sync

on:
  schedule:
    - cron: '0 14 * * 0'
  workflow_dispatch:

permissions:
  contents: write
  pull-requests: write
  issues: write

jobs:
  sync:
    uses: YOUR-ORG/.github/.github/workflows/lineage-policy-sync-smart.yml@stable
    with:
      consumption_pattern: direct
      baseline_repo: YOUR-ORG/lineage-baseline
      baseline_ref: stable
      prefer_pr: false         # Try direct push first
      auto_merge: true         # Enable auto-merge if PR created
      stagger_minutes: 5       # Random delay to prevent rate limits
```

**How the smart workflow works:**

```mermaid
graph TD
    A[Policy Sync Triggered] --> B[Random Delay<br/>0-5 minutes]
    B --> C[Check Policy Compliance]
    C -->|In Sync| D[Exit - No Action Needed]
    C -->|Out of Sync| E[Pull Latest with Rebase]

    E --> F[Materialize Policy Files]
    F --> G[Validate Content<br/>Check for CHANGEME/TODO]

    G --> H{Has Changes?}
    H -->|No| D
    H -->|Yes| I{Prefer PR?}

    I -->|No| J[Try Direct Push]
    I -->|Yes| N[Create PR]

    J -->|Success| K[Done ✅]
    J -->|Branch Protection| N[Create PR]
    J -->|Merge Conflict| L[Pull & Retry Once]

    L -->|Fixed| M[Push]
    L -->|Still Conflicts| N[Create PR]

    M --> K

    N --> O{Has Issues?}
    O -->|Conflicts or Errors| P[Create PR<br/>Skip Auto-merge<br/>Create Issue]
    O -->|Clean| Q[Create PR<br/>Enable Auto-merge]

    Q --> R[Auto-approve Workflow]
    R --> S[CI Validation]
    S --> T[Merge PR]
    T --> K

    P --> U[Manual Review Required]

    style K fill:#90EE90
    style D fill:#FFE4B5
    style U fill:#FFB6C1
```

1. **Staggered execution**: Random delay (0-5 min) prevents 500 repos hitting API simultaneously
2. **Attempts direct push first** (fastest path)
3. **Falls back to PR if**:
   - Branch protection requires PRs
   - Merge conflicts need resolution
   - You set `prefer_pr: true`
4. **Validates content**: Checks for placeholder text (CHANGEME, TODO)
5. **Handles conflicts gracefully**: Creates PR with conflict markers for manual resolution
6. **Auto-merges when safe**: Skips auto-merge if conflicts or validation errors

**Rate Limit Protection:**

GitHub's API limits content creation to:
- 80 PRs per minute
- 500 PRs per hour

The smart workflow handles this with:
- **Staggered execution**: Random delays spread load
- **Batched processing**: Natural throttling from workflow runtime
- **Retry logic**: Handles transient failures

**Why this is the best approach:**
- **One workflow for all scenarios** (simpler for users)
- **Optimal performance** (direct push when possible)
- **Graceful degradation** (PR fallback when needed)
- **Built-in safety** (validation, conflict handling)
- **Scale-ready** (rate limit protection for 500+ repos)

---

## Recommended Implementation

### Solving the "Hundreds of Repos" Problem

Large organizations often manage hundreds or thousands of repositories that need consistent policies. When a security policy changes, a new license is adopted or coding standards are updated, that change must propagate to every repository in the organization.

The traditional governance approach requires creating individual pull requests to each repository, having them reviewed by repository owners and manually merging them. For an organization with 500 repositories, a single policy change creates 500 separate pull requests that each require human attention. This creates massive operational overhead and delays policy adoption across the organization.

Organizations face a core tension when implementing governance at scale between maintaining review processes and avoiding operational bottlenecks.

### Core Tension

**Option A: Automated Sync**
The automated policy sync workflow runs weekly and commits changes directly to the main branch. This eliminates the manual overhead of creating hundreds of pull requests across repositories when baseline policies change. However, it bypasses the review process entirely, which some organizations require for governance.

**Option B: Manual Sync**
Users run sync commands locally and create pull requests manually for review. This maintains the review process and audit trail that many organizations need. However, it recreates the original bottleneck problem where policy updates require manual intervention across potentially hundreds of repositories.

### The Hybrid Solution

The recommended approach combines automation with governance controls using GitHub's branch protection features. Configure branch protection rules that require pull requests even for automated workflows.

When baseline repository changes are reviewed and approved, they should be free to propagate and sync to external repositories without additional review. Auto-merging should be enabled as long as CI build tests pass.

The automated workflow creates pull requests instead of committing directly to main. Code owners can auto-approve policy-only changes while maintaining an audit trail. Auto-merge eliminates manual work while GitHub's branch protection provides the governance controls organizations need.

This approach solves the policy cascade bottleneck by handling the "hundreds of repos" problem through automation, while branch protection provides review gates where needed. When a single policy change in the baseline needs to flow out to hundreds of consumer repositories, automation eliminates the manual overhead while maintaining governance controls.

### Auto-Approved PR Workflow

The `lineage-policy-sync-pr.yml` reusable workflow implements the hybrid solution by creating pull requests for policy updates with optional auto-approval:

```yaml
# .github/workflows/policy-sync.yml
name: Policy Sync
on:
  schedule:
    - cron: '0 14 * * 0'
  workflow_dispatch:

permissions:
  contents: write
  issues: write
  pull-requests: write

jobs:
  sync:
    uses: YOUR-ORG/.github/.github/workflows/lineage-policy-sync-pr.yml@stable
    with:
      consumption_pattern: direct
      baseline_repo: YOUR-ORG/lineage-baseline
      baseline_ref: stable
      create_pr: true
      auto_approve: true
```

**Key Features:**
- Creates PRs instead of direct commits for audit trails
- Supports auto-approval with `auto_approve: true`
- Works with all consumption patterns (direct, configuration-driven, template-based)
- Integrates with GitHub's auto-merge when checks pass
- Provides detailed PR descriptions with change summaries

**Enterprise Setup:**
1. Enable branch protection requiring PR reviews
2. Configure auto-merge in repository settings
3. Set up auto-approval workflow for policy sync PRs
4. CI checks validate policy changes before merge

**Required Auto-Approval Workflow:**
```yaml
# .github/workflows/auto-approve.yml
name: Auto Approve Policy Updates
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  auto-approve:
    uses: YOUR-ORG/.github/.github/workflows/lineage-auto-approve.yml@stable
    with:
      pr_title_pattern: "Policy Sync"
      actor_filter: "github-actions[bot]"
      merge_method: "squash"
      enable_auto_merge: true
      require_checks: true
```

This pattern is demonstrated in [lineage-demo3](https://github.com/Lineage-org/lineage-demo3) which showcases pure upstream consumption with zero maintenance overhead.

**Demo3's Minimal CI Approach:**
```yaml
# Simple CI that just validates policies are in sync
jobs:
  policy-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v31
      - name: Verify policies are in sync
        run: nix run github:Lineage-org/lineage-baseline#check
```

This is the simplest possible Lineage integration - no flake.nix, no templates, just direct validation.

### Pure Apps in CI

Pure Nix apps for pack creation and policy management can be run in CI workflows for automated governance tasks without requiring file materialization in the repository.

---

## Customization Checklist

When you fork this baseline for your organization, follow this checklist to customize it for your needs:

### Before You Start

- [ ] Fork both [`.github`](https://github.com/Lineage-org/.github) and [`lineage-baseline`](https://github.com/Lineage-org/lineage-baseline) repositories to your organization
- [ ] Clone your forked `lineage-baseline` locally
- [ ] Have your organization details ready (name, copyright holder, security contact)

### Required Customizations

#### 1. License Pack

**Option A: Fetch from SPDX (Recommended)**
```bash
cd lineage-baseline
nix run .#fetch-license -- Apache-2.0 --holder "ACME Corp" --year 2025
git add packs/license.nix
```

**Option B: Import existing LICENSE file**
```bash
nix run .#import-policy -- --file LICENSE
# Edit packs/license.nix to adjust copyrightHolder and copyrightYear
git add packs/license.nix
```

**Option C: Edit manually**
- [ ] Edit `packs/license.nix`
- [ ] Update `copyrightHolder` variable
- [ ] Update `copyrightYear` variable
- [ ] Replace license text if needed

#### 2. Security Pack

- [ ] Edit `packs/security.nix`
- [ ] Update `securityEmail` to your security team's email
- [ ] Adjust `responseTime` if needed
- [ ] Review `supportedVersions` list

#### 3. Code Owners Pack

- [ ] Edit `packs/codeowners.nix`
- [ ] Update `org` variable to your GitHub organization name
- [ ] Customize `rules` list with your team structure

#### 4. Editor Config Pack

- [ ] Edit `packs/editorconfig.nix`
- [ ] Customize `defaultSettings` for your org's standards
- [ ] Add language-specific rules in `languageSettings`

#### 5. Dependabot Pack

- [ ] Edit `packs/dependabot.nix`
- [ ] Review `updates` list for your tech stack
- [ ] Adjust `schedule` if needed (daily, weekly, monthly)

### Optional Customizations

#### 6. Import Existing Policies

If you have existing policy files, import them:

```bash
# Auto-import all recognized files
nix run .#import-policy -- --auto

# Or import specific files
nix run .#import-policy -- --file .editorconfig
nix run .#import-policy -- --file SECURITY.md
nix run .#import-policy -- --file .github/CODEOWNERS
```

Review and adjust the generated packs as needed.

### Commit and Tag

Once customizations are complete:

```bash
# Commit all changes
git add packs/
git commit -m "feat: customize baseline for YOUR-ORG"
git push origin main

# Tag as stable
git tag -a stable -m "Initial baseline for YOUR-ORG"
git push origin stable
```

### Test Your Baseline

Before rolling out to consumer repos, test locally:

```bash
# In a test directory
nix flake init -t github:YOUR-ORG/lineage-baseline

# Sync policies
nix run .#sync

# Verify files
ls -la LICENSE SECURITY.md .editorconfig .github/CODEOWNERS

# Check content matches your customizations
cat LICENSE  # Should show your org's copyright
cat SECURITY.md  # Should show your security email
```

### Update `.github` Repository

Update your forked `.github` repository workflows to reference your baseline:

```yaml
# In .github/.github/workflows/lineage-ci.yml
- name: Materialize policies
  run: |
    nix run "github:YOUR-ORG/lineage-baseline?ref=${{ inputs.channel }}"#sync
```

Tag and push:

```bash
git add .
git commit -m "feat: update workflows for YOUR-ORG baseline"
git push origin main

git tag -a stable -m "Initial stable release"
git push origin stable
```

### Rollout to Consumer Repos

Now your baseline is ready! Consumer repos can use it:

```bash
# In any project repo
nix flake init -t github:YOUR-ORG/lineage-baseline

# Customize which packs to enable in flake.nix
# Then sync and commit
nix run .#sync
git add LICENSE SECURITY.md .editorconfig .github/
git commit -m "feat: add Lineage policies"
```

---

## Tagging Policy

This repository is versioned via the `stable` tag to provide a consistent reference point for Lineage workflows.

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

## Supply Chain Security - Nixpkgs Updates

The baseline repository implements automated nixpkgs dependency updates with validation testing before promotion to stable. This follows the supply chain security best practices by pinning nixpkgs to specific commit hashes instead of branch references.

### Update Strategy

Lineage uses a three-stage strategy for managing both baseline changes and nixpkgs dependencies:

**unstable branch** - Primary development branch containing latest baseline changes and nixpkgs updates. Unstable tag automatically tracks this branch for immediate testing availability.

**main branch** - Production branch with validated changes. Automatically updated via auto-merge PRs when unstable branch validation passes.

**stable tag** - Production-ready version used by consumer repositories. Automatically updated when main branch CI completes successfully.

### Automated Update Pipeline

```mermaid
graph TD
    A[Weekly Schedule<br/>Sunday 2 AM UTC] --> B[Fetch Latest Commit<br/>nixos-unstable]
    B --> C[Update flake.nix<br/>Pin to Commit Hash]
    C --> D[Update flake.lock]
    D --> E[Commit to unstable branch]
    E --> F[Auto-update unstable tag]

    F --> G[Branch Validation Workflow]
    G --> H[Comprehensive Testing]
    H --> I[Flake check + Apps + Content validation]
    I --> J{All Tests Pass?}

    J -->|Yes| K[Create PR to main<br/>Add promote-to-stable label]
    J -->|No| L[Create Issue<br/>Alert Maintainers]

    K --> M[Auto-approve & merge PR]
    M --> N[Main Branch CI]
    N --> O[Update .stable-candidate]
    O --> P[Trigger stable promotion]
    P --> Q[Update stable tag]
    Q --> R[Consumer Repos Auto-sync<br/>Updated Policies]

    style A fill:#e1f5fe
    style F fill:#fff3cd
    style J fill:#ffe4b5
    style M fill:#4CAF50
    style Q fill:#4CAF50
    style L fill:#ffcdd2
```

### Workflows

The baseline repository includes workflows that integrate with the complete automation pipeline:

**update-nixpkgs.yml** - Runs weekly on Sunday at 2 AM UTC. Fetches latest nixos-unstable commit hash. Updates flake.nix with pinned commit. Commits to unstable branch (triggering validation workflow).

**ci.yml** - Baseline CI that runs on main branch. Validates flake integrity and apps. Updates .stable-candidate file and triggers stable promotion when validation passes.

The complete automation leverages reusable workflows from the `.github` repository for branch validation and promotion orchestration.

### Manual Updates

For emergency nixpkgs updates outside the weekly schedule:

```bash
# Trigger manual update via GitHub Actions
gh workflow run update-nixpkgs.yml

# Or update locally on unstable branch
git checkout unstable
LATEST=$(gh api repos/NixOS/nixpkgs/commits/nixos-unstable --jq '.sha')
sed -i "s|github:NixOS/nixpkgs/[^\"]*|github:NixOS/nixpkgs/$LATEST|g" flake.nix
nix flake update
git add flake.nix flake.lock
git commit -m "Update nixpkgs to $LATEST"
git push origin unstable
# unstable tag auto-updates, validation workflow triggers automatically
```

### Rollback Procedures

If a nixpkgs update causes issues:

```bash
# Find previous working commit on unstable branch
git checkout unstable
git log --oneline --grep="Update nixpkgs"

# Reset unstable branch to previous commit
git reset --hard PREVIOUS_COMMIT_HASH
git push --force-with-lease origin unstable
# unstable tag auto-updates, validation workflow triggers

# For emergency stable rollback (bypasses validation)
git tag -f stable KNOWN_GOOD_COMMIT
git push -f origin stable
```

### Security Rationale

Pinning nixpkgs to explicit commit hashes provides better supply chain security:

**Auditability** - Commit hashes in flake.nix are immediately visible without checking flake.lock

**Intentional updates** - Changes require explicit commit modification, preventing accidental updates via `nix flake update`

**Compliance** - Aligns with SECURITY-BASELINE.md recommendations for critical trust points

**Traceability** - Clear git history of when and why nixpkgs was updated

---

## Baseline Promotion Workflow

The baseline repository implements a complete automation workflow that eliminates manual steps while maintaining validation and safety. The workflow supports development through an unstable branch with automatic promotion to main and stable tags.

### Complete Automation Process

The baseline uses a three-stage automated promotion system:

**unstable branch** - Main development branch where all commits are made. Unstable tag automatically tracks this branch for immediate testing availability.

**main branch** - Production branch containing validated changes. Automatically updated via auto-merge PRs when unstable branch validation passes.

**stable tag** - Production-ready baseline version used by consumer repositories. Automatically updated when main branch CI completes successfully.

### Complete Automation Architecture

```mermaid
graph TD
    A[Push to unstable branch] --> B[Update unstable tag<br/>Immediate testing availability]
    B --> C[Branch Validation Workflow]
    C --> D[Comprehensive Testing]
    D --> E[Flake check + Apps + Content validation]
    E --> F{Validation Passed?}

    F -->|Yes| G[Create PR to main<br/>Add promote-to-stable label]
    F -->|No| H[Create/Update Issue<br/>Assign to author]

    G --> I[Auto-approve PR]
    I --> J[Auto-merge to main]
    J --> K[Main Branch CI]
    K --> L[Update .stable-candidate]
    L --> M[Trigger Stable Promotion]
    M --> N[Update stable tag]
    N --> O[Consumer Repos Auto-sync<br/>Updated Policies]

    H --> P[Fix Issues]
    P --> A

    style A fill:#e1f5fe
    style B fill:#fff3cd
    style G fill:#4CAF50
    style J fill:#4CAF50
    style N fill:#4CAF50
    style O fill:#90EE90
    style H fill:#ffcdd2
```

### Unstable Branch Development

**The unstable branch is the primary development branch** where all changes are made. Key characteristics:

- **Unstable tag tracks unstable branch**: Every commit to unstable automatically updates the unstable tag
- **Immediate testing**: Teams can test latest changes via `nix run github:ORG/baseline?ref=unstable#sync`
- **No manual tagging**: Tag updates are fully automated
- **Continuous validation**: Each push triggers validation and potential promotion

### Automation Benefits

**Zero Manual Promotion Steps:**
- Development commits to unstable branch trigger complete pipeline
- Validation, PR creation, approval, and stable promotion are automated
- No human intervention required for successful changes
- Issues only created when validation fails

**Fast Feedback Loop:**
- Unstable tag updates immediately for testing
- Validation results available within minutes
- Failed validation creates assigned issues with details
- Successful validation promotes to stable automatically

**Complete Audit Trail:**
- All changes flow through PR process with promote-to-stable label
- .stable-candidate file tracks promotion progression
- GitHub Actions provide complete workflow history
- Issues document any validation failures

### Validation Steps

Before creating a promotion PR, the system validates:

1. **Flake integrity** - `nix flake check` passes on multiple platforms
2. **App functionality** - All baseline apps build and run correctly
3. **Pack syntax** - All policy packs have valid Nix syntax
4. **Cross-platform** - Builds succeed on Linux and macOS
5. **Input validation** - New packs are scanned for security issues

### Consumer Repository Impact

Consumer repositories detect baseline updates through their policy sync workflows. When the stable tag is updated:

1. **Template-based repositories**: The consumer template flake.lock is automatically updated to reference the new stable baseline version
2. **Direct consumption repositories**: Policy sync workflows detect changes on next CI run and show "out of sync" status
3. **Policy synchronization**: Can be triggered manually via Actions tab or waits for scheduled weekly sync

This staged promotion system ensures that baseline changes are thoroughly validated and intentionally approved before affecting consumer repositories across the organization.

---

## Stable Candidate Coordination

The baseline repository uses a `.stable-candidate` file to coordinate promotion from main branch to stable tag. This file acts as a temporary promotion signal in the complete automation pipeline.

### How .stable-candidate Works

**File Purpose:**
- Acts as a "promotion queue" marker for commits ready to be tagged as stable
- Contains the commit hash that baseline CI has validated and approved for stable promotion
- Serves as the handoff mechanism between baseline CI and the promote-to-stable workflow

**Lifecycle:**
1. **Creation**: Baseline CI creates/updates `.stable-candidate` when validation passes on main branch
2. **Content**: Contains the exact commit hash that passed validation: `a1b2c3d4e5f6...`
3. **Consumption**: Promote-to-stable workflow reads this file to know which commit to promote
4. **Removal**: File is deleted after successful promotion to stable tag

### Architecture Benefits

**Decoupled Workflows:**
- Baseline CI focuses on validation and candidate marking
- Promote-to-stable workflow focuses on tag management and promotion
- Clear separation of concerns with file-based coordination

**Auditability:**
- File presence indicates promotion is pending
- File absence indicates no pending promotions
- Git history shows exactly when candidates were marked and promoted

**Reliability:**
- Atomic operations prevent race conditions
- File-based handoff is more reliable than API calls
- Workflow failures are visible through file state

### Integration with Complete Automation

The `.stable-candidate` file enables the complete automation pipeline:

```
unstable branch push → validation → PR with promote-to-stable label →
auto-merge to main → baseline CI → .stable-candidate creation →
promote-to-stable trigger → stable tag update → .stable-candidate removal
```

**Key Points:**
- File only exists temporarily between main branch CI and stable promotion
- Multiple commits may update the file before promotion occurs
- Latest commit hash in the file always wins for promotion
- Removal after promotion prevents duplicate promotions

### File Location and Format

**Location:** `.stable-candidate` in repository root
**Format:** Single line containing commit hash
**Example:** `ca83961a2f5e8b6c9d1234567890abcdef123456`

This architecture ensures that stable promotions are both automated and traceable while maintaining clear workflow boundaries.

---

## Lineage vs Traditional Policy Distribution

Traditional policy distribution systems use automated pull requests to propagate policy updates across repositories. When a baseline changes, the system creates PRs in every consumer repository, requiring manual review and merge.

| Feature | Traditional (PR-based) | Lineage (Flake-based) |
|---------|------------------------|------------------------|
| **Distribution** | Automated PRs | Direct Nix materialization |
| **Review Process** | Manual PR review required | No PRs needed |
| **Update Speed** | Hours/days (PR workflow) | Instant (next sync) |
| **Customization** | Fork + modify files | Nix expressions |
| **Reproducibility** | Git-based | Nix-based (hermetic) |
| **Configuration** | YAML config files | Nix flake inputs |

**Key Advantage:** Consumer repos automatically get the latest policies through flake inputs - no PR bottleneck!

---

## Importance of the Baseline

This repository serves as the **official baseline** for Lineage.
It defines how organizational workflows interpret and apply shared policy, serving as the root of consistency and traceability for all consumer repositories.

When another organization forks Lineage, this repository is where they establish **their own governance baseline** - defining what policies, governance and automation rules will apply across their environment.
By maintaining and versioning this baseline, each organization can evolve its own standards while still inheriting the reproducible and declarative structure that Lineage provides.
