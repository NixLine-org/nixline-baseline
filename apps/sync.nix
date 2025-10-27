{ pkgs, lib, helpers, packsLib }:

pkgs.writeShellApplication {
  name = "nixline-sync";

  runtimeInputs = [ pkgs.coreutils ];

  text = ''
    set -euo pipefail

    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                    NixLine Sync                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    # Get requested packs from environment (default: persistent packs only)
    NIXLINE_PACKS="''${NIXLINE_PACKS:-editorconfig,codeowners,security,license,dependabot}"

    echo "Packs: $NIXLINE_PACKS"
    echo ""

    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (packName: pack:
      let
        filesScript = lib.concatStringsSep "\n" (lib.mapAttrsToList (path: content: ''
          if echo "$NIXLINE_PACKS" | grep -qw "${packName}"; then
            mkdir -p "$(dirname "${path}")"
            cat > "${path}" << 'NIXLINE_EOF'
            ${content}
            NIXLINE_EOF
            echo "[+] ${packName}: ${path}"
          fi
        '') pack.files);
      in filesScript
    ) packsLib.packModules)}

    echo ""
    echo "Sync complete"
  '';
}
