# Lineage Core Utilities
#
# Core file manipulation functions used by sync and check apps.
# Provides shell script generators for writing and validating files.

{ pkgs }:

rec {
  # Write a file to disk (used by sync)
  writeFile = path: content: pkgs.writeShellScript "write-${baseNameOf path}" ''
    mkdir -p "$(dirname "${path}")"
    cat > "${path}" << 'LINEAGE_EOF'
    ${content}
    LINEAGE_EOF
    echo "✓ Wrote ${path}"
  '';

  # Materialize multiple files at once
  materializeFiles = files: pkgs.writeShellScript "materialize-files" ''
    ${pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (path: content: ''
      mkdir -p "$(dirname "${path}")"
      cat > "${path}" << 'LINEAGE_EOF'
${content}
LINEAGE_EOF
      echo "✓ Materialized ${path}"
    '') files)}
  '';

  # Check if a file exists and matches expected content
  checkFile = path: expectedContent: pkgs.writeShellScript "check-${baseNameOf path}" ''
    if [[ ! -f "${path}" ]]; then
      echo "✗ Missing: ${path}"
      exit 1
    fi

    if ! diff -q "${path}" <(cat << 'LINEAGE_EOF'
${expectedContent}
LINEAGE_EOF
    ) >/dev/null 2>&1; then
      echo "✗ Out of sync: ${path}"
      exit 1
    fi

    echo "✓ Valid: ${path}"
  '';

  # Validate multiple files
  validateFiles = files: pkgs.writeShellScript "validate-files" ''
    failed=0
    ${pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (path: content: ''
      if [[ ! -f "${path}" ]]; then
        echo "✗ Missing: ${path}"
        failed=1
      elif ! diff -q "${path}" <(cat << 'LINEAGE_EOF'
${content}
LINEAGE_EOF
      ) >/dev/null 2>&1; then
        echo "✗ Out of sync: ${path}"
        failed=1
      else
        echo "✓ Valid: ${path}"
      fi
    '') files)}

    if [[ $failed -eq 1 ]]; then
      echo ""
      echo "Run 'nix run .#sync' to fix"
      exit 1
    fi
  '';
}
