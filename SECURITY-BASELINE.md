# Security Guidelines for Lineage Baseline Repository

## Critical Security Requirements

This baseline repository is a **critical trust point** that affects all consumer repositories in your organization. A compromise here propagates everywhere.

## Required Security Measures

### 1. Branch Protection (RECOMMENDED)

**CI-First Security Model (Recommended):**
```yaml
# Primary protection through comprehensive CI validation
- Require status checks to pass (MANDATORY)
- Require branches to be up to date (MANDATORY)

# Allow automation bypass for validated workflows
- Bypass pull request requirements for:
  - github-actions[bot] (automated policy sync, dependency updates)
  - dependabot[bot] (security updates)

# Require PRs only for:
  - Manual changes by humans
  - Failed CI validation that needs review
  - Complex changes requiring discussion
```

**Legacy Model (Still Supported):**
```yaml
- Require pull request reviews (2+ reviewers for baseline changes)
- Dismiss stale PR approvals when new commits are pushed
- Require review from CODEOWNERS
- Include administrators in restrictions
```

**Why CI-First is Better:**
- [+] **Faster security updates** - no human bottleneck for validated changes
- [+] **Better automation** - dependency updates, policy sync work seamlessly
- [+] **Focus human review** on complex changes that actually need it
- [+] **Stronger validation** - comprehensive CI catches issues better than manual review
- [+] **Audit trail preserved** - all changes logged with context and validation results

### 2. Access Control

**Repository Access:**
- **Admin**: Security team ONLY (2-3 people max)
- **Write**: Platform team (limited group)
- **Read**: Organization members
- **No outside collaborators** on baseline repo

**CODEOWNERS Required:**
```
# All policy packs require security team review
/packs/ @your-org/security-team @your-org/platform-team

# Workflow changes require platform team review
/.github/ @your-org/platform-team

# Nix apps require both teams
/apps/ @your-org/security-team @your-org/platform-team
```

### 3. Code Review Requirements

**Every PR Must:**
- Have security team approval for `/packs/` changes
- Have platform team approval for `/apps/` changes
- Pass all CI checks including:
  - `nix flake check`
  - Content validation (no CHANGEME/TODO)
  - License validation
  - Security contact validation

### 4. Supply Chain Security

**Flake Lock Management:**
```bash
# Verify all inputs before updating
nix flake metadata
nix flake info

# Pin specific commits, not branches
inputs.nixpkgs.url = "github:NixOS/nixpkgs/abc123def456";

# Review flake.lock changes carefully
git diff flake.lock
```

**Dependency Verification:**
- Audit all flake inputs quarterly
- Use specific commit hashes, not branch references
- Enable GitHub Dependabot for security alerts

### 5. Secret Management

**NEVER commit:**
- API keys
- Passwords
- Private keys
- Internal URLs
- Email addresses (use parameters)

**Use parameterization:**
```nix
# Good - parameterized
security-email = params.security-email or "security@example.com";

# Bad - hardcoded
security-email = "security@mycompany.com";
```

### 6. Workflow Security

**GitHub Actions Tokens:**
- Use minimal permissions
- Never use `permissions: write-all`
- Prefer fine-grained PATs over GITHUB_TOKEN where needed
- Rotate tokens quarterly

**Workflow Hardening:**
```yaml
# Pin action versions to commit SHAs
- uses: actions/checkout@8ade135a41bc03ea155e62e844d188df1ea18608 # v4.1.0

# Not this
- uses: actions/checkout@v4
```

### 7. Content Validation

**Required Validations:**
```nix
# In apps/check/default.nix
checks = [
  # No secrets in files
  "! grep -r 'PRIVATE KEY' ."
  "! grep -r 'password.*=' ."

  # No internal URLs
  "! grep -r 'internal.*mycompany.com' ."

  # No unparameterized emails
  "! grep -r '@mycompany.com' packs/"
];
```

### 8. Monitoring & Alerts

**Enable:**
- GitHub Advanced Security (if available)
- Secret scanning
- Code scanning with CodeQL
- Dependency scanning
- Branch protection rule violations alerts
- Audit log streaming to SIEM

**Alert on:**
- Force pushes to main
- Branch protection changes
- CODEOWNERS modifications
- New admin users
- Outside collaborator additions

### 9. Incident Response

**If Baseline is Compromised:**

1. **IMMEDIATELY:**
   ```bash
   # Lock down baseline repo
   gh repo edit YOUR-ORG/nixline-baseline --enable-issues=false --enable-wiki=false

   # Disable all policy sync workflows org-wide
   # Use organization Actions settings to disable workflows
   ```

2. **Notify all consumer repos** to halt policy sync

3. **Audit all recent changes:**
   ```bash
   git log --oneline -20
   git diff HEAD~5..HEAD
   ```

4. **Revert to known-good state:**
   ```bash
   git revert [compromised-commits]
   git push origin main
   ```

5. **Force all consumers to re-validate:**
   - Trigger manual policy review
   - Require explicit approval before re-enabling sync

### 10. Security Testing

**Regular Security Audits:**
```bash
# Quarterly: Full dependency audit
nix flake check --all-systems

# Annually: External security review
```

**GitHub Security Features:**
Organizations should enable and configure GitHub's built-in security features:
- **Secret scanning** - Automatically detects committed secrets
- **Dependabot** - Vulnerability scanning and automated updates
- **CodeQL** - Static analysis for security vulnerabilities
- **Security advisories** - Notifications for known vulnerabilities

**Automated Security Tests:**
```yaml
name: Security Validation

on:
  pull_request:
    paths:
      - 'packs/**'
      - 'apps/**'

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check for secrets
        run: |
          # Scan for common secret patterns
          ! grep -r "sk-[a-zA-Z0-9]{32}" .
          ! grep -r "token.*=.*['\"][a-zA-Z0-9]{40}" .

      - name: Validate no internal URLs
        run: |
          ! grep -r "internal\|corp\|private" packs/
```

## Red Flags to Watch For

- Unexpected changes to `/apps/` directory
- New shell script execution in packs
- Changes to `.github/workflows/` permissions
- Modifications to CODEOWNERS
- PRs from new contributors to critical paths
- Large binary files in PRs
- Obfuscated Nix code

## Recommended Baseline Fork Strategy

For maximum security, organizations should:

1. **Fork** the baseline privately
2. **Enable** all security features
3. **Audit** thoroughly before first use
4. **Lock** to specific commits, not branches
5. **Monitor** continuously with alerts
6. **Test** in isolated environment first

## Contact

Security issues with Lineage baseline should be reported to:
[YOUR-ORG-SECURITY-EMAIL]

For upstream Lineage security issues:
Open a security advisory at https://github.com/Lineage-org/nixline-baseline/security/advisories