{ config, pkgs, testvim, utils, lib, username, inputs, packagename, ...  }@args: let
in {
  imports = [
  ];

  xdg.enable = true;

  home.shellAliases = {
  };
  home.sessionVariables = {
    EDITOR = "nvim";
  };
  home.packages = with pkgs; [
  ];
  home.file = {
  };

  testvim = {
    enable = true;
    packageNames = [ packagename ];
    packages = {
      ${packagename} = utils.mergeCatDefs testvim.packageDefinitions.${packagename} ({ pkgs, ... }: {
        settings = {
        };
        categories = {
          nix_test_info = {
            hello' = "world!";
          };
        };
      });
    };
  };
}
