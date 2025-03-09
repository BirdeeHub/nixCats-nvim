{ config, pkgs, package, utils, lib, inputs, packagename, moduleNamespace, ...  }@args:
lib.setAttrByPath moduleNamespace {
  enable = true;
  packageNames = [ packagename ];
  packageDefinitions.replace = {
    ${packagename} = { pkgs, ... }: {
      settings = {
      };
      categories = {
        cowboy = true;
        nixCats_test_names = {
          nixos_hello = true;
        };
      };
    };
  };
  users.testuser = {
    enable = true;
    packageNames = [ packagename ];
    packageDefinitions.replace = {
      ${packagename} = { pkgs, ... }: {
        settings = {
        };
        categories = {
          cowboy = true;
          fi = true;
          nixCats_test_names = {
            nixos_user_hello = true;
          };
        };
      };
    };
  };
}
