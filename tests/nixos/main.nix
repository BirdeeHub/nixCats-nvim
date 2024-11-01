{ config, pkgs, package, utils, lib, hostname, username, inputs, packagename, ...  }@args: {
  ${packagename} = {
    enable = true;
    packageNames = [ packagename ];
    packages = {
      ${packagename} = utils.mergeCatDefs package.packageDefinitions.${packagename} ({ pkgs, ... }: {
        settings = {
        };
        categories = {
          nixCats_test_names = {
            helloNixosModule = true;
          };
        };
      });
    };
  };
}
