# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license
{
  description = "A Lua-natic's neovim flake, with extra cats! nixCats!";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # see :help nixCats.flake.inputs
    # If you want your plugin to be loaded by the standard overlay,
    # i.e. if it wasnt on nixpkgs, but doesnt have an extra build step.
    # Then you should name it "plugins-something"
    # If you wish to define a custom build step not handled by nixpkgs,
    # then you should name it in a different format, and deal with that in the
    # overlay defined for custom builds in the overlays directory.
    # for specific tags, branches and commits, see:
    # https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#examples

    "plugins-hlargs" = {
      url = "github:m-demare/hlargs.nvim";
      flake = false;
    };

    # will be removed after the following pr is accepted:
    # https://github.com/folke/lazy.nvim/pull/1259
    # If you do use it before then, keep in mind that this one creates
    # a directory named lazy-nvim while the official
    # will create one named lazy.nvim
    # this is because it is imported via our defaultPluginOverlay right now.
    # this is relevant when you fetch the lazypath in your lua.
    # and thus you will need to change it once the upstream occurs.
    "plugins-lazy-nvim" = {
      url = "github:BirdeeHub/lazy.nvim";
      flake = false;
    };

    # neovim = {
    #   url = "github:neovim/neovim";
    #   flake = false;
    # };

    # a flake import. We will import this one with an overlay
    # but you could also import the package itself instead.
    # overlays are just nice if they are offered.
    nixd.url = "github:nix-community/nixd";
  };

  # see :help nixCats.flake.outputs
  outputs = { self, nixpkgs, flake-utils, ... }@inputs: let
    utils = (import ./nix/utils).utils;
    luaPath = "${./.}";
    # the following extra_pkg_config contains any values
    # which you want to pass to the config set of nixpkgs
    # import nixpkgs { config = extra_pkg_config; inherit system; }
    # will not apply to module imports
    # as that will have your system values
    extra_pkg_config = {
      # allowUnfree = true;
    };
    # sometimes our overlays require a ${system} to access the overlay.
    # management of this variable is one of the harder parts of using flakes.

    # so I have done it here in an interesting way to keep it out of the way.

    # First, we will define just our overlays per system.
    # later we will pass them into the builder, and the resulting pkgs set
    # will get passed to the categoryDefinitions and packageDefinitions
    # which follow this section.

    # this allows you to use pkgs.${system} whenever you want in those sections
    # without fear.
    system_resolved = flake-utils.lib.eachDefaultSystem (system: let
      # see :help nixCats.flake.outputs.overlays
      dependencyOverlays = (import ./overlays inputs) ++ [
        # This overlay grabs all the inputs named in the format
        # `plugins-<pluginName>`
        # Once we add this overlay to our nixpkgs, we are able to
        # use `pkgs.neovimPlugins`, which is a set of our plugins.
        (utils.standardPluginOverlay inputs)
        # add any flake overlays here.
        inputs.nixd.overlays.default
      ];
      # these overlays will be wrapped with ${system}
      # and we will call the same flake-utils function
      # later on to access them.
    in { inherit dependencyOverlays; });
    inherit (system_resolved) dependencyOverlays;
    # see :help nixCats.flake.outputs.categories
    # and
    # :help nixCats.flake.outputs.categoryDefinitions.scheme
    categoryDefinitions = { pkgs, settings, categories, name, ... }@packageDef: {
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
          universal-ctags
          ripgrep
          fd
        ];
        neonixdev = {
          # also you can do this.
          inherit (pkgs) nix-doc nil lua-language-server nixd;
          # nix-doc tags will make your tags much better in nix
          # but only if you have nil as well for some reason
        };
      };

      # This is for plugins that will load at startup without using packadd:
      startupPlugins = {
        debug = with pkgs.vimPlugins; [
          nvim-dap
          nvim-dap-ui
          nvim-dap-virtual-text
        ];
        neonixdev = with pkgs.vimPlugins; [
          neodev-nvim
          neoconf-nvim
        ];
        # yes these category names are arbitrary
        markdown = with pkgs.vimPlugins; [
          # yes it knows this isn't with pkgs.vimPlugins
          pkgs.nixCatsBuilds.markdown-preview-nvim
        ];
        lazy = with pkgs.neovimPlugins; [
          # lazy will be imported via pkgs.vimPlugins.lazy-nvim
          # after upstream pr is accepted.
          lazy-nvim
        ];
        general = {
          gitPlugins = with pkgs.neovimPlugins; [
            hlargs
          ];
          vimPlugins = {
            # you can make a subcategory
            cmp = with pkgs.vimPlugins; [
              # cmp stuff
              nvim-cmp
              luasnip
              friendly-snippets
              cmp_luasnip
              cmp-buffer
              cmp-path
              cmp-nvim-lua
              cmp-nvim-lsp
              cmp-cmdline
              cmp-nvim-lsp-signature-help
              cmp-cmdline-history
              lspkind-nvim
            ];
            general = with pkgs.vimPlugins; [
              telescope-fzf-native-nvim
              plenary-nvim
              telescope-nvim
              # treesitter
              nvim-treesitter-textobjects
              nvim-treesitter.withAllGrammars
              # This is for if you only want some of the grammars
              # (nvim-treesitter.withPlugins (
              #   plugins: with plugins; [
              #     nix
              #     lua
              #   ]
              # ))
              # other
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
              undotree
              nvim-surround
              indent-blankline-nvim
              nvim-web-devicons
            ];
          };
        };
        # You can retreive information from the
        # packageDefinitions of the package this was packaged with.
        # :help nixCats.flake.outputs.categoryDefinitions.scheme
        themer = with pkgs.vimPlugins;
          (builtins.getAttr categories.colorscheme {
              # Theme switcher without creating a new category
              "onedark" = onedark-nvim;
              "catppuccin" = catppuccin-nvim;
              "catppuccin-mocha" = catppuccin-nvim;
              "tokyonight" = tokyonight-nvim;
              "tokyonight-day" = tokyonight-nvim;
            }
          );
          # This is obviously a fairly basic usecase for this, but still nice.
          # Checking packageDefinitions also has the bonus
          # of being able to be easily set by importing flakes.
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




    # packageDefinitions:

    # Now build a package with specific categories from above
    # All categories you wish to include must be marked true,
    # but false may be omitted.
    # This entire set is also passed to nixCats for querying within the lua.
    # It is directly translated to a Lua table, and a get function is defined.
    # The get function is to prevent errors when querying subcategories.

    # see :help nixCats.flake.outputs.packageDefinitions
    packageDefinitions = {
      # these also recieve our pkgs variable
      nixCats = { pkgs, ... }@misc: {
        # see :help nixCats.flake.outputs.settings
        settings = {
          # will check for config in the store rather than .config
          wrapRc = true;
          configDirName = "nixCats-nvim";
          aliases = [ "vi" "vim" ];
          # nvimSRC = inputs.neovim;
        };
        # see :help nixCats.flake.outputs.packageDefinitions
        categories = {
          generalBuildInputs = true;
          markdown = true;
          general.vimPlugins = true;
          general.gitPlugins = true;
          custom = true;
          neonixdev = true;
          test = {
            subtest1 = true;
          };
          debug = false;
          # this does not have an associated category of plugins, 
          # but lua can still check for it
          lspDebugMode = false;
          # by default, we dont want lazy.nvim
          # we could omit this for the same effect
          lazy = false;
          # you could also pass something else:
          themer = true;
          colorscheme = "onedark";
          theBestCat = "says meow!!";
          theWorstCat = {
            thing'1 = [ "MEOW" "HISSS" ];
            thing2 = [
              {
                thing3 = [ "give" "treat" ];
              }
              "I LOVE KEYBOARDS"
            ];
            thing4 = "couch is for scratching";
          };
          # see :help nixCats
        };
      };
      regularCats = { pkgs, ... }@misc: {
        settings = {
          # will check for config in .config rather than the store
          # this is mostly useful for fast iteration while editing lua.
          wrapRc = false;
          # will now look for nixCats-nvim within .config and .local and others
          configDirName = "nixCats-nvim";
          aliases = [ "testCat" ];
        };
        categories = {
          generalBuildInputs = true;
          markdown = true;
          general = true;
          custom = true;
          neonixdev = true;
          test = true;
          lspDebugMode = false;
          themer = true;
          colorscheme = "catppuccin";
          theBestCat = "says meow!!";
          theWorstCat = {
            thing'1 = [ "MEOW" "HISSS" ];
            thing2 = [
              {
                thing3 = [ "give" "treat" ];
              }
              "I LOVE KEYBOARDS"
            ];
            thing4 = "couch is for scratching";
          };
        };
      };
    };
  in

  # In this section, the main thing you will need to do is change the default package name
  # to the name of the packageDefinitions entry you wish to use as the default.

  # see :help nixCats.flake.outputs.exports
  flake-utils.lib.eachDefaultSystem (system: let
    inherit (utils) baseBuilder;
    customPackager = baseBuilder luaPath {
      inherit nixpkgs system dependencyOverlays extra_pkg_config;
    } categoryDefinitions;
    nixCatsBuilder = customPackager packageDefinitions;
    # this is just for using utils such as pkgs.mkShell
    # The one used to build neovim is resolved inside the builder
    # and is passed to our categoryDefinitions and packageDefinitions
    pkgs = import nixpkgs { inherit system; };
  in {
    # these outputs will be wrapped with ${system} by flake-utils.lib.eachDefaultSystem

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
    # and you export overlays so people dont have to redefine stuff.
    inherit customPackager;
  }) // {

    # these outputs will be NOT wrapped with ${system}

    # we also export a nixos module to allow configuration from configuration.nix
    nixosModules.default = utils.mkNixosModules {
      defaultPackageName = "nixCats";
      inherit dependencyOverlays;
      inherit luaPath categoryDefinitions packageDefinitions nixpkgs;
    };
    # and the same for home manager
    homeModule = utils.mkHomeModules {
      defaultPackageName = "nixCats";
      inherit dependencyOverlays;
      inherit luaPath categoryDefinitions packageDefinitions nixpkgs;
    };
    # now we can export some things that can be imported in other
    # flakes, WITHOUT needing to use a system variable to do it.
    # and update them into the rest of the outputs returned by the
    # eachDefaultSystem function.
    inherit utils categoryDefinitions packageDefinitions dependencyOverlays;
    inherit (utils) templates baseBuilder;
    keepLuaBuilder = utils.baseBuilder luaPath;
  };

}
