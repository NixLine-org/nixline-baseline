{ pkgs, lib, config ? {} }:


let
  utils = import ../lib/pack-utils.nix { inherit pkgs lib; };
in

# Example 1: Simple static pack
utils.template-utils.createStaticPack {
  packName = "example-simple";
  ecosystem = "universal";
  description = "Simple example pack";

  files = {
    ".example" = ''
      # This is a simple configuration file
      # It demonstrates basic file generation
      setting1 = value1
      setting2 = value2
    '';
  };

  # Optional custom checks (validation automatically added)
  customChecks = [
    {
      name = "example-validation";
      check = ''
        echo "[✓] Example pack configured successfully"
      '';
    }
  ];
}

# Example 2: Parameterized pack (for organizations needing customization)
# Uncomment this to see parameterized pack pattern:
#
# utils.template-utils.createParameterizedPack {
#   packName = "example-advanced";
#   ecosystem = "universal";
#   description = "Example with organization customization";
#
#   # Default configuration values (overridable via .nixline.toml)
#   configDefaults = {
#     setting1 = "default_value";
#     setting2 = true;
#     list_setting = ["item1" "item2"];
#   };
#
#   # Function that generates files based on configuration
#   fileGenerators = packConfig: orgConfig: {
#     ".example-advanced" = utils.generateIniFile {
#       main = {
#         organization = orgConfig.name;
#         setting1 = packConfig.setting1;
#         setting2 = packConfig.setting2;
#       };
#       advanced = {
#         items = packConfig.list_setting;
#       };
#     };
#   };
#
#   # Optional custom validation
#   customChecks = [
#     {
#       name = "advanced-validation";
#       check = ''
#         echo "[✓] Advanced example with org: ${orgConfig.name}"
#       '';
#     }
#   ];
# } config