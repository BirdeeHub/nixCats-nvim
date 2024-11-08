{ config, pkgs, package, utils, lib, username, inputs, packagename, ...  }@args: let
in {
  imports = [
  ];

  xdg.enable = true;

  home.shellAliases = {
  };
  home.sessionVariables = {
    EDITOR = "${packagename}";
  };
  home.packages = with pkgs; [
  ];
  home.file = {
  };

  ${packagename} = {
    enable = true;
    packageNames = [ packagename ];
    packageDefinitions.replace = {
      ${packagename} = { pkgs, ... }: {
        settings = {
        };
        categories = {
          nixCats_test_names = {
            home_hello = true;
          };
        };
      };
    };
  };
}
