{ config, pkgs, package, utils, lib, inputs, packagename, ...  }@args: {
  ${packagename} = {
    enable = true;
    packageNames = [ packagename ];
    packages = {
      ${packagename} = utils.mergeCatDefs package.packageDefinitions.${packagename} ({ pkgs, ... }: {
        settings = {
        };
        categories = {
          nixCats_test_names = {
            nixos_hello = true;
          };
        };
      });
    };
  };
}
