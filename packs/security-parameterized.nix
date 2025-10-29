{ pkgs, lib, config ? {} }:

#
# SECURITY PACK (PARAMETERIZED)
#
# This pack materializes a comprehensive SECURITY.md file following GitHub best practices.
# Based on industry standards from Microsoft, Node.js, and GitHub's recommendations.
#
# CONFIGURATION:
# This pack can be customized via .nixline.toml configuration:
#
# [organization]
# security_email = "security@mycompany.com"
# name = "MyCompany"
#
# [security]
# acknowledgment_time = "5 business days"
# response_time = "10 business days"
# bug_bounty = true
#
# [packs.security]
# custom_file = "path/to/custom-security.md"  # Use custom SECURITY.md file
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

  # Pack-specific configuration
  packConfig = config.packs.security or {};
  customFile = packConfig.custom_file or null;

  # Security policy configuration
  responseTime = packConfig.response_time or "promptly";
  disclosurePolicy = packConfig.disclosure_policy or "coordinated";

  # Default supported versions - can be overridden in config
  defaultVersions = [
    { version = "Latest"; supported = true; notes = "All current releases"; }
    { version = "Previous major"; supported = true; notes = "Security fixes only"; }
    { version = "< Previous major"; supported = false; notes = "End of life"; }
  ];

  supportedVersions = config.security.supported_versions or defaultVersions;

  # Generate version table
  versionTable = lib.concatStringsSep "\n" (map (v:
    "| ${v.version} | ${if v.supported then ":white_check_mark:" else ":x:"} |"
  ) supportedVersions);

  # Generate disclosure policy section
  disclosurePolicyText =
    if disclosurePolicy == "coordinated" then ''
      ## Disclosure Policy

      We follow a coordinated disclosure policy. When we receive a security bug report, we will:

      1. Confirm the problem and determine affected versions
      2. Audit code to find similar problems
      3. Prepare fixes for all supported releases
      4. Coordinate with the reporter on disclosure timeline
      5. Release patches and public disclosure simultaneously

      We typically aim for a 90-day disclosure timeline, but this may be adjusted based on the complexity of the issue.
    ''
    else if disclosurePolicy == "immediate" then ''
      ## Disclosure Policy

      We follow an immediate disclosure policy. Security issues are addressed and disclosed as quickly as possible:

      1. Confirm the problem and determine affected versions
      2. Prepare fixes for all supported releases
      3. Release patches immediately
      4. Publish security advisory within 24 hours
    ''
    else ''
      ## Disclosure Policy

      When we receive a security bug report, we will:

      1. Confirm the problem and determine affected versions
      2. Audit code to find similar problems
      3. Prepare fixes for all supported releases
      4. Release patches as soon as possible
    '';

in
{
  files = {
    "SECURITY.md" =
      if customFile != null then
        if builtins.pathExists customFile then
          builtins.readFile customFile
        else
          throw "Custom SECURITY.md file ${customFile} does not exist"
      else ''
      # Security Policy

      ## Supported Versions

      We release patches for security vulnerabilities in the following versions:

      | Version | Supported          |
      | ------- | ------------------ |
      ${versionTable}

      ## Reporting a Vulnerability

      If you discover a security vulnerability within this project, please send an email to **${securityConfig.email}**. All security vulnerabilities will be ${responseTime} addressed.

      **Please do not open public issues for security vulnerabilities.**

      ### What to Include

      When reporting a vulnerability, please include:

      - Description of the vulnerability
      - Steps to reproduce the issue
      - Affected versions (if known)
      - Potential impact assessment
      - Any suggested mitigations

      ${disclosurePolicyText}

      ## Security Best Practices

      Users of this project should:

      - Keep dependencies up to date
      - Monitor security advisories for this repository
      - Follow the principle of least privilege
      - Report suspected vulnerabilities promptly

      ## Comments on this Policy

      If you have suggestions on how this process could be improved, please submit a pull request or contact ${securityConfig.email}.

      ## Additional Information

      This security policy follows industry best practices and is regularly updated to reflect current security standards.

      ---
      *This security policy was generated by NixLine.*
    '';
  };

  checks = [
    {
      name = "security-contact-valid";
      check = ''
        if [[ -f SECURITY.md ]]; then
          echo "Checking security contact email format..."
          if ! grep -q '@' SECURITY.md; then
            echo "Error: SECURITY.md appears to be missing a valid email address"
            exit 1
          fi
          echo "Security contact check passed"
        fi
      '';
    }
  ];
}