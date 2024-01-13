# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license

# This is an empty nixCats config.
# you may import this template directly into your nvim folder
# and then add plugins to categories here,
# and call the plugins with their default functions
# within your lua, rather than through the nvim package manager's method.
# Use the help, and the example repository https://github.com/BirdeeHub/nixCats-nvim

# It allows for easy adoption of nix,
# while still providing all the extra nix features immediately.
# Configure in lua, check for a few categories, set a few settings,
# output packages with combinations of those categories and settings.

# All the same options you make here will be automatically exported in a form available
# in home manager and in nixosModules, as well as from other flakes.
# each section is tagged with its relevant help section.

{
  description = "A Lua-natic's neovim flake, with extra cats! nixCats!";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixCats.url = "github:BirdeeHub/nixCats-nvim/frankenstein";
  };

  # see :help nixCats.flake.outputs
  outputs = { self, nixpkgs, flake-utils, nixCats, ... }@inputs: let
      utils = nixCats.utils;
    # This line makes this package available for all major systems
    # system is just a string like "x86_64-linux" or "aarch64-darwin"
    in flake-utils.lib.eachDefaultSystem (system: let

      # you may define more overlays in the overlays directory, and import them
      # in the default.nix file in that directory.
      # see overlays/default.nix for how to add more overlays in that directory.
      # or see :help nixCats.flake.nixperts.overlays
      dependencyOverlays = [ (utils.mergeOverlayLists nixCats.dependencyOverlays.${system}
      ((import ./overlays inputs) ++ [
        (utils.standardPluginOverlay inputs)
        # add any flake overlays here.
      ])) ];
      pkgs = import nixpkgs {
        inherit system;
        overlays = dependencyOverlays;
        # config.allowUnfree = true;
      };

      # Now that our plugin inputs/overlays and pkgs have been defined,
      # We define a function to facilitate package building for particular categories
      # This allows us to define categories and settings 
      # for our package later and then choose a package.

      # see :help nixCats.flake.outputs.builder
      inherit (utils) baseBuilder;
      nixCatsBuilder = baseBuilder "${./.}" { inherit pkgs dependencyOverlays;} categoryDefinitions packageDefinitions;
        # notice how it doesn't care that the last 2 are defined lower in the file?

      # see :help nixCats.flake.outputs.categories
      # and
      # :help nixCats.flake.outputs.categoryDefinitions.scheme
      categoryDefinitions = packageDef: {
        # to define and use a new category, simply add a new list to a set here, 
        # and later, you will include categoryname = true; in the set you
        # provide when you build the package using this builder function.
        # see :help nixCats.flake.outputs.packageDefinitions for info on that section.

        # propagatedBuildInputs:
        # this section is for dependencies that should be available
        # at BUILD TIME for plugins. WILL NOT be available to PATH
        # However, they WILL be available to the shell 
        # and neovim path when using nix develop
        propagatedBuildInputs = {
          generalBuildInputs = with pkgs; [
          ];
        };

        # lspsAndRuntimeDeps:
        # this section is for dependencies that should be available
        # at RUN TIME for plugins. Will be available to PATH within neovim terminal
        # this includes LSPs
        lspsAndRuntimeDeps = {
          general = with pkgs; [
            universal-ctags ripgrep fd gcc
            nix-doc nil lua-language-server nixd
          ];
        };

        # This is for plugins that will load at startup without using packadd:
        startupPlugins = {
          lazy = with pkgs.neovimPlugins; [
            lazy-nvim
          ];
          general = {
            gitPlugins = with pkgs.neovimPlugins; [
              hlargs
            ];
            vimPlugins = with pkgs.vimPlugins; [
              neodev-nvim
              neoconf-nvim
              nvim-cmp
              friendly-snippets
              luasnip
              cmp_luasnip
              cmp-path
              cmp-nvim-lsp
              telescope-fzf-native-nvim
              plenary-nvim
              telescope-nvim
              nvim-treesitter-textobjects
              nvim-treesitter.withAllGrammars
              nvim-lspconfig
              fidget-nvim
              lualine-nvim
              gitsigns-nvim
              which-key-nvim
              comment-nvim
              vim-sleuth
              vim-fugitive
              vim-rhubarb
              vim-repeat
              indent-blankline-nvim
            ];
          };
          # You can retreive information from the
          # packageDefinitions of the package this was packaged with.
          # :help nixCats.flake.outputs.categoryDefinitions.scheme
          themer = with pkgs.vimPlugins;
            (builtins.getAttr packageDef.categories.colorscheme {
                # Theme switcher without creating a new category
                "onedark" = onedark-nvim;
                # "catppuccin" = catppuccin-nvim;
                # "tokyonight" = tokyonight-nvim;
              }
            );
        };

        # not loaded automatically at startup.
        # use with packadd and an autocommand in config to achieve lazy loading
        optionalPlugins = {
          custom = with pkgs.nixCatsBuilds; [ ];
          gitPlugins = with pkgs.neovimPlugins; [ ];
          general = with pkgs.vimPlugins; [ ];
        };

        # environmentVariables:
        # this section is for environmentVariables that should be available
        # at RUN TIME for plugins. Will be available to path within neovim terminal
        environmentVariables = {
          test = {
            subtest1 = {
              CATTESTVAR = "It worked!";
            };
            subtest2 = {
              CATTESTVAR3 = "It didn't work!";
            };
          };
        };

        # If you know what these are, you can provide custom ones by category here.
        # If you dont, check this link out:
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
        extraWrapperArgs = {
          test = [
            '' --set CATTESTVAR2 "It worked again!"''
          ];
        };

        # lists of the functions you would have passed to
        # python.withPackages or lua.withPackages
        extraPythonPackages = {
          test = (_:[]);
        };
        extraPython3Packages = {
          test = (_:[]);
        };
        extraLuaPackages = {
          test = [ (_:[]) ];
        };
      };

      # see :help nixCats.flake.outputs.settings
      settings = {
        nixCats = {
          # will check for config in the store rather than .config
          wrapRc = true;
          configDirName = "testerstart-nvim";
          viAlias = false;
          vimAlias = true;
          # nvimSRC = inputs.neovim;
        };
      };


      # And then build a package with specific categories from above here:
      # All categories you wish to include must be marked true,
      # but false may be omitted.
      # This entire set is also passed to nixCats for querying within the lua.

      # see :help nixCats.flake.outputs.packageDefinitions
      packageDefinitions = {
        nixCats = {
          settings = settings.nixCats; 
          categories = {
            lazy = true;
            generalBuildInputs = true;
            general = true;
            # this does not have an associated category of plugins, 
            # but lua can still check for it
            lspDebugMode = false;
            # you could also pass something else:
            themer = true;
            colorscheme = "onedark";
            theBestCat = "says meow!!";
            theWorstCat = {
              thing'1 = [ "MEOW" "HISSS" ];
              thing2 = [
                "I LOVE KEYBOARDS"
                {
                  thing3 = [ "give" "treat" ];
                }
              ];
            };
            # see :help nixCats
          };
        };
      };
    in



    # see :help nixCats.flake.outputs.exports
    {
      # this will make a package out of each of the packageDefinitions defined above
      # and set the default package to the one named here.
      packages = utils.mkPackages nixCatsBuilder packageDefinitions "nixCats";

      # this will make an overlay out of each of the packageDefinitions defined above
      # and set the default overlay to the one named here.
      overlays = utils.mkOverlays nixCatsBuilder packageDefinitions "nixCats";

      # choose your package for devShell
      # and add whatever else you want in it.
      devShell = pkgs.mkShell {
        name = "nixCats";
        packages = [ (nixCatsBuilder "nixCats") ];
        inputsFrom = [ ];
        shellHook = ''
        '';
      };

      # To choose settings and categories from the flake that calls this flake.
      customPackager = baseBuilder "${./.}" { inherit pkgs dependencyOverlays;} categoryDefinitions;

      # and you export this so people dont have to redefine stuff.
      inherit dependencyOverlays;
      inherit categoryDefinitions;
      inherit packageDefinitions;

      # we also export a nixos module to allow configuration from configuration.nix
      nixosModules.default = utils.mkNixosModules {
        defaultPackageName = "nixCats";
        luaPath = "${./.}";
        inherit dependencyOverlays
          categoryDefinitions packageDefinitions;
      };
      # and the same for home manager
      homeModule = utils.mkHomeModules {
        defaultPackageName = "nixCats";
        luaPath = "${./.}";
        inherit dependencyOverlays
          categoryDefinitions packageDefinitions;
      };

    }
  ) // {
    inherit utils;
    inherit (utils) templates baseBuilder;
    keepLuaBuilder = utils.baseBuilder "${./.}";
  };
}
