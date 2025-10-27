{ pkgs, lib }:

pkgs.writeShellApplication {
  name = "nixline-fetch-license";

  runtimeInputs = [ pkgs.curl pkgs.jq ];

  text = ''
    set -euo pipefail

    show_usage() {
      cat << EOF
╔════════════════════════════════════════════════════════════╗
║              NixLine License Fetcher                       ║
╚════════════════════════════════════════════════════════════╝

Fetch license text from SPDX and generate license pack.

Usage:
  nixline-fetch-license <license-id> [--holder "Name"] [--year YYYY]
  nixline-fetch-license --list

Options:
  <license-id>     SPDX license identifier (e.g., Apache-2.0, MIT, GPL-3.0)
  --holder NAME    Copyright holder name (default: "ACME Corp")
  --year YYYY      Copyright year (default: current year)
  --list           List common SPDX license identifiers

Examples:
  # Fetch Apache 2.0 license
  nixline-fetch-license Apache-2.0 --holder "My Company" --year 2025

  # Fetch MIT license
  nixline-fetch-license MIT --holder "ACME Corp"

  # List common licenses
  nixline-fetch-license --list

Output:
  Generated pack file is written to packs/license.nix
EOF
    }

    list_common_licenses() {
      cat << EOF
Common SPDX License Identifiers:

  Apache-2.0          Apache License 2.0
  MIT                 MIT License
  GPL-3.0-only        GNU General Public License v3.0 only
  GPL-3.0-or-later    GNU General Public License v3.0 or later
  AGPL-3.0-only       GNU Affero General Public License v3.0
  BSD-3-Clause        BSD 3-Clause "New" or "Revised" License
  BSD-2-Clause        BSD 2-Clause "Simplified" License
  ISC                 ISC License
  MPL-2.0             Mozilla Public License 2.0
  LGPL-3.0-only       GNU Lesser General Public License v3.0 only
  CC0-1.0             Creative Commons Zero v1.0 Universal
  Unlicense           The Unlicense

For full list, see: https://spdx.org/licenses/
EOF
    }

    # Parse arguments
    LICENSE_ID=""
    COPYRIGHT_HOLDER="ACME Corp"
    COPYRIGHT_YEAR=$(date +%Y)

    while [[ $# -gt 0 ]]; do
      case $1 in
        --help|-h)
          show_usage
          exit 0
          ;;
        --list)
          list_common_licenses
          exit 0
          ;;
        --holder)
          COPYRIGHT_HOLDER="$2"
          shift 2
          ;;
        --year)
          COPYRIGHT_YEAR="$2"
          shift 2
          ;;
        *)
          LICENSE_ID="$1"
          shift
          ;;
      esac
    done

    if [[ -z "$LICENSE_ID" ]]; then
      show_usage
      exit 1
    fi

    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              Fetching License Text                         ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "License: $LICENSE_ID"
    echo "Holder:  $COPYRIGHT_HOLDER"
    echo "Year:    $COPYRIGHT_YEAR"
    echo ""

    # Fetch license from GitHub's license API
    LICENSE_URL="https://raw.githubusercontent.com/spdx/license-list-data/main/text/$LICENSE_ID.txt"

    echo "Fetching license text..."
    if ! LICENSE_TEXT=$(curl -fsSL "$LICENSE_URL"); then
      echo "Error: Failed to fetch license $LICENSE_ID" >&2
      echo "Make sure the SPDX ID is correct. Run with --list to see common licenses." >&2
      exit 1
    fi

    echo "✓ License text retrieved"
    echo ""

    # Escape single quotes for Nix
    LICENSE_TEXT=$(echo "$LICENSE_TEXT" | sed "s/''/'\\\\''''/g")

    # Generate pack file
    mkdir -p packs

    cat > packs/license.nix << EOF
{ pkgs, lib }:

#
# LICENSE PACK
#
# Generated using: nixline-fetch-license $LICENSE_ID
# License: $LICENSE_ID
# Copyright Holder: $COPYRIGHT_HOLDER
# Copyright Year: $COPYRIGHT_YEAR
#
# To regenerate or change license:
#   nix run .#fetch-license <SPDX-ID> --holder "Your Org" --year YYYY
#
# Common licenses:
#   Apache-2.0, MIT, GPL-3.0-only, BSD-3-Clause, ISC, MPL-2.0
#   Run 'nix run .#fetch-license --list' for more
#

let
  # EDIT THIS: Your organization's copyright info
  copyrightHolder = "$COPYRIGHT_HOLDER";
  copyrightYear = "$COPYRIGHT_YEAR";
  spdxId = "$LICENSE_ID";

  # License text from SPDX
  licenseText = ''
$LICENSE_TEXT
  '';

  # Copyright notice
  copyrightNotice = "\\\\n\\\\nCopyright \\\${copyrightYear} \\\${copyrightHolder}";
in

{
  files = {
    "LICENSE" = licenseText + copyrightNotice;
  };

  checks = [];
}
EOF

    echo "✓ Generated packs/license.nix"
    echo ""
    echo "Next steps:"
    echo "  1. Review packs/license.nix"
    echo "  2. Adjust copyrightHolder and copyrightYear if needed"
    echo "  3. Commit to your baseline repository"
  '';
}
