{ config, pkgs, package, utils, lib, username, inputs, packagename, ...  }@args: let
in {
  imports = [
  ];

  # these options dont actually do anything because
  # we dont evaluate the entire HM config only the nvim from it
  # but you could get their value via config variable still.
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

  # nixCats module:
  ${packagename} = {
    enable = true;
    # packageNames = [ packagename ];
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
