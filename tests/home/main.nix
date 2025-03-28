{ config, pkgs, package, utils, lib, username, inputs, packagename, moduleNamespace, ...  }@args: let
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
} //
# nixCats module:
(lib.setAttrByPath moduleNamespace {
  enable = true;
  addOverlays = [
    (utils.standardPluginOverlay { plugins-visual-whitespace = inputs.visual-whitespace; })
  ];
  categoryDefinitions.merge = { pkgs, settings, categories, name, extra, mkPlugin, ... }@packageDef: {
    startupPlugins = {
      overlaytest = [
        pkgs.neovimPlugins.visual-whitespace
      ];
    };
  };
  # packageNames = [ packagename ];
  packageDefinitions.replace = {
    ${packagename} = { pkgs, ... }: {
      settings = {
      };
      categories = {
        overlaytest = true;
        fi = true;
        foe = true;
        cowboy = true;
        nixCats_test_names = {
          home_hello = true;
        };
      };
    };
  };
})

