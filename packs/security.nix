{ pkgs, lib, config ? {} }:

#
# SECURITY PACK
#
# This pack materializes a comprehensive SECURITY.md file following GitHub best practices.
# Based on industry standards from Microsoft, Node.js, and GitHub's recommendations.
#
# HOW TO CUSTOMIZE FOR YOUR ORG:
# 1. Update configuration in .nixline.toml or via config parameter
# 2. Adjust supportedVersions based on your release cadence
# 3. Modify response times to match your SLA
# 4. Add organization-specific security policies
#

let
  # Configuration with sensible defaults
  securityConfig = {
    email = config.organization.security_email or config.organization.email or "security@example.com";
    acknowledgmentTime = config.security.acknowledgment_time or "5 business days";
    responseTime = config.security.response_time or "10 business days";
    bugBounty = config.security.bug_bounty or false;
    orgName = config.organization.name or "this organization";
  };

  # Default supported versions - can be overridden in config
  defaultVersions = [
    { version = "Latest"; supported = true; notes = "All current releases"; }
    { version = "Previous major"; supported = true; notes = "Security fixes only"; }
    { version = "< Previous major"; supported = false; notes = "End of life"; }
  ];

  supportedVersions = config.security.supported_versions or defaultVersions;

  # Generate version table with optional notes
  versionTable = lib.concatStringsSep "\n" (map (v:
    "| ${v.version} | ${if v.supported then ":white_check_mark:" else ":x:"} | ${v.notes or ""} |"
  ) supportedVersions);

  # Bug bounty section if enabled
  bugBountySection = lib.optionalString securityConfig.bugBounty ''

    ## Bug Bounty Program

    ${securityConfig.orgName} operates a bug bounty program to encourage responsible security research.

    **Scope**: This program covers security vulnerabilities in our supported software versions.

    **Rewards**: Compensation is provided based on the severity and impact of discovered vulnerabilities.

    **Platform**: Reports should be submitted through our security contact email for coordination.
  '';

  # Additional guidelines section
  guidelinesSection = ''

    ## Security Research Guidelines

    When investigating potential security issues, please:

    - **Act in good faith**: Avoid violating privacy, degrading services, or accessing unauthorized data
    - **Be patient**: Allow reasonable time for investigation and remediation before disclosure
    - **Be respectful**: Follow our code of conduct and communicate professionally
    - **Stay within scope**: Focus on security vulnerabilities, not general bugs or feature requests

    ### What We Consider Security Issues

    - Authentication bypasses
    - Authorization flaws
    - Data exposure vulnerabilities
    - Code injection (SQL, XSS, etc.)
    - Cryptographic weaknesses
    - Remote code execution
    - Denial of service vulnerabilities

    ### What We Don't Consider Security Issues

    - Missing security headers without demonstrated impact
    - Theoretical vulnerabilities without proof of concept
    - Issues in unsupported or end-of-life versions
    - Social engineering attacks
    - Physical security issues
  '';
in

{
  files = {
    "SECURITY.md" = ''
      # Security Policy

      ${securityConfig.orgName} takes the security of our software seriously. We appreciate your efforts to responsibly disclose any vulnerabilities you may find.

      ## Supported Versions

      We provide security updates for the following versions:

      | Version | Supported | Notes |
      | ------- | --------- | ----- |
      ${versionTable}

      ## Reporting a Vulnerability

      **Please do not report security vulnerabilities through public GitHub issues.**

      Instead, please report potential security vulnerabilities by emailing **${securityConfig.email}**.

      ### What to Include in Your Report

      To help us understand and resolve the issue quickly, please include:

      - A clear description of the vulnerability
      - Steps to reproduce the issue
      - Potential impact assessment
      - Any suggested fixes or mitigations
      - Your contact information for follow-up

      ### What to Expect

      After submitting a report, you can expect:

      - **Acknowledgment**: We will acknowledge receipt of your report within **${securityConfig.acknowledgmentTime}**
      - **Initial Response**: We will provide an initial assessment within **${securityConfig.responseTime}**
      - **Regular Updates**: We will keep you informed of our progress throughout the investigation
      - **Resolution**: We will notify you when the issue is resolved and publicly disclosed

      ## Responsible Disclosure

      We are committed to working with security researchers under responsible disclosure principles:

      1. **Investigation**: We will investigate all legitimate reports and work to fix valid issues
      2. **Communication**: We will maintain open communication throughout the process
      3. **Credit**: We will publicly credit researchers who discover vulnerabilities (unless they prefer to remain anonymous)
      4. **No Legal Action**: We will not pursue legal action against researchers who follow these guidelines

      ${bugBountySection}

      ${guidelinesSection}

      ## Security Updates

      Security updates will be announced through:

      - Repository security advisories
      - Release notes and changelogs
      - Our organization's security mailing list (if available)

      ## Contact

      For questions about this security policy, please contact **${securityConfig.email}**.

      ## Policy Updates

      This security policy may be updated from time to time. Please check back regularly for the latest version.

      ---

      *Last updated: 2025-01-29*
    '';
  };

  checks = [
    {
      name = "security-policy-exists";
      check = ''
        if [[ ! -f "SECURITY.md" ]]; then
          echo "ERROR: SECURITY.md file is missing"
          exit 1
        fi

        if ! grep -q "security@" SECURITY.md; then
          echo "WARNING: No security email found in SECURITY.md"
        fi

        echo "✓ Security policy exists and contains contact information"
      '';
    }
  ];
}
