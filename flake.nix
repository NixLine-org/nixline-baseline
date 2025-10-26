{
  description = "NixLine baseline demo flake (for CI verification)";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  outputs = { self, nixpkgs }: let
    mk = system: let pkgs = import nixpkgs { inherit system; }; in {
      sync  = { type="app"; program = "${pkgs.hello}/bin/hello"; };
      check = { type="app"; program = "${pkgs.hello}/bin/hello"; };
    };
  in {
    apps.x86_64-linux = mk "x86_64-linux";
    apps.aarch64-linux = mk "aarch64-linux";
    apps.x86_64-darwin = mk "x86_64-darwin";
    apps.aarch64-darwin = mk "aarch64-darwin";
  };
}
