# Architecture & Consumption

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
security_email = "security@lineage.run"
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
            C1["actions/checkout@v5"]
            C2["DeterminateSystems/nix-installer-action@v21"]
            C3["github-script@v7"]
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
  - uses: actions/checkout@v5
  - uses: DeterminateSystems/nix-installer-action@v21
```

Organizations forking Lineage should maintain this pattern by:
1. Forking both `.github` and `lineage-baseline` repositories
2. Updating workflow references to point to their organization
3. Never calling actions directly from baseline workflows

---

## Understanding Pack Propagation

**How it works:**

1. You edit a pack file in your forked baseline (e.g., `packs/license.nix`)
2. You commit and push to your baseline repo
3. You re-tag `stable` in your baseline repo
4. **All consumer repos automatically get the updated file on their next sync**

No pull requests for baseline changes. No manual updates. No drift.

This is the key difference from traditional policy distribution systems that use automated pull requests - changes propagate instantly through flake updates instead of requiring PR reviews.

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
