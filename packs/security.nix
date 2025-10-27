{ pkgs, lib }:

#
# SECURITY PACK
#
# This pack materializes a SECURITY.md file documenting security policies and reporting.
# When enabled, all repositories receive this security policy.
#
# HOW TO CUSTOMIZE FOR YOUR ORG:
# 1. Update securityEmail below
# 2. Adjust supportedVersions based on your release cadence
# 3. Modify responseTime to match your SLA
#

let
  # EDIT THIS: Your organization's security contact
  securityEmail = "security@example.com";

  # EDIT THIS: Expected response time
  responseTime = "promptly";  # e.g., "within 24 hours", "within 2 business days"

  # EDIT THIS: Supported versions table
  supportedVersions = [
    { version = "latest"; supported = true; }
    { version = "< latest"; supported = false; }
  ];

  # Generate version table
  versionTable = lib.concatStringsSep "\n" (map (v:
    "| ${v.version} | ${if v.supported then ":white_check_mark:" else ":x:"} |"
  ) supportedVersions);
in

{
  files = {
    "SECURITY.md" = ''
      # Security Policy

      ## Supported Versions

      We release patches for security vulnerabilities in the following versions:

      | Version | Supported          |
      | ------- | ------------------ |
      ${versionTable}

      ## Reporting a Vulnerability

      If you discover a security vulnerability within this project, please send an email to ${securityEmail}. All security vulnerabilities will be ${responseTime} addressed.

      Please do not open public issues for security vulnerabilities.

      ## Disclosure Policy

      When we receive a security bug report, we will:

      1. Confirm the problem and determine affected versions
      2. Audit code to find similar problems
      3. Prepare fixes for all supported releases
      4. Release patches as soon as possible

      ## Comments on this Policy

      If you have suggestions on how this process could be improved, please submit a pull request.
    '';
  };

  checks = [];
}
