# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license

# Welcome to the main example config of nixCats!
# there is a minimal flake the starter templates use
# within the nix directory without the nixpkgs input,
# but this one would work too!
# Every config based on nixCats is a full nixCats.

# This main example config doesnt use lazy.nvim, and
# it loads everything via nix. This example config
# consists of everything outside of ./nix

# It has some useful tricks
# in it, especially for lsps, so if you have any questions,
# first look through the docs, and then here!
# It has examples of most of the things you would want to do
# in your main nvim configuration.

# If there is still not adequate info, ask in discussions
# on the nixCats repo (or open a PR to add the info to the help!)
{
  description = "A Lua-natic's neovim flake, with extra cats! nixCats!";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # see :help nixCats.flake.inputs
    # If you want your plugin to be loaded by the standard overlay,
    # i.e. if it wasnt on nixpkgs, but doesnt have an extra build step.
    # Then you should name it "plugins-something"
    # If you wish to define a custom build step not handled by nixpkgs,
    # then you should name it in a different format, and deal with that in the
    # overlay defined for custom builds in the overlays directory.
    # for specific tags, branches and commits, see:
    # https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#examples

    # No longer fetched to avoid forcing people to import it, but this remains here as a tutorial.
    # How to import it into your config is shown farther down in the startupPlugins set.
    # You put it here like this, and then below you would use it with `pkgs.neovimPlugins.hlargs`

    # "plugins-hlargs" = {
    #   url = "github:m-demare/hlargs.nvim";
    #   flake = false;
    # };

    # neovim-nightly-overlay = {
    #   url = "github:nix-community/neovim-nightly-overlay";
    # };

  };

  # see :help nixCats.flake.outputs
  outputs = { self, nixpkgs, ... }@inputs: let
    utils = import ./nix;
    luaPath = "${./.}";
    # this is flake-utils eachSystem
    forEachSystem = utils.eachSystem nixpkgs.lib.platforms.all;
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

    # this allows you to use ${pkgs.system} whenever you want in those sections
    # without fear.
    inherit (forEachSystem (system: let
      # see :help nixCats.flake.outputs.overlays
      dependencyOverlays = (import ./overlays inputs) ++ [
        # This overlay grabs all the inputs named in the format
        # `plugins-<pluginName>`
        # Once we add this overlay to our nixpkgs, we are able to
        # use `pkgs.neovimPlugins`, which is a set of our plugins.
        (utils.standardPluginOverlay inputs)
        # add any flake overlays here.
      ];
      # these overlays will be wrapped with ${system}
      # and we will call the same utils.eachSystem function
      # later on to access them.
    in { inherit dependencyOverlays; })) dependencyOverlays;
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
        general = with pkgs; [
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
          inherit (pkgs) nix-doc lua-language-server nixd;
          # and each will be its own sub category
        };
        lint = with pkgs; [
        ];
        debug = with pkgs; [
        ];
        format = with pkgs; [
        ];
      };

      # This is for plugins that will load at startup without using packadd:
      startupPlugins = {
        debug = with pkgs.vimPlugins; [
          nvim-nio
          nvim-dap
          nvim-dap-ui
          nvim-dap-virtual-text
        ];
        lint = with pkgs.vimPlugins; [
          nvim-lint
        ];
        format = with pkgs.vimPlugins; [
          conform-nvim
        ];
        # yes these category names are arbitrary
        markdown = with pkgs.vimPlugins; [
          markdown-preview-nvim
        ];
        general = {
          gitPlugins = [
            # If it was included in your flake inputs as plugins-hlargs,
            # this would be how to add that plugin in your config.
            # pkgs.neovimPlugins.hlargs
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
              telescope-ui-select-nvim
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
              # lualine-lsp-progress
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
              oil-nvim
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
        neonixdev = with pkgs.vimPlugins; [
          # loaded in the same file as the lsps are configured.
          # see there or at `:h nixCats.LSPs` for more info on lazy loading.
          lazydev-nvim
        ];
        custom = with pkgs.nixCatsBuilds; [ ];
        gitPlugins = with pkgs.neovimPlugins; [ ];
        general = with pkgs.vimPlugins; [ ];
      };

      # shared libraries to be added to LD_LIBRARY_PATH
      # variable available to nvim runtime
      sharedLibraries = {
        general = with pkgs; [
          # libgit2
        ];
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

      # get the path to this python environment
      # in your lua config via
      # vim.g.python3_host_prog
      # or run from nvim terminal via :!<packagename>-python3
      extraPython3Packages = {
        test = (_:[]);
      };
      # populates $LUA_PATH and $LUA_CPATH
      extraLuaPackages = {
        general = [ (_:[]) ];
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
          aliases = [ "vim" "vimcat" ];
          # neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;
        };
        # see :help nixCats.flake.outputs.packageDefinitions
        categories = {
          markdown = true;
          general.vimPlugins = true;
          general.gitPlugins = true;
          custom = true;
          lint = true;
          format = true;
          neonixdev = true;
          test = {
            subtest1 = true;
          };
          debug = false;
          # this does not have an associated category of plugins, 
          # but lua can still check for it
          lspDebugMode = false;
          # you could also pass something else:
          # see :help nixCats
          themer = true;
          colorscheme = "onedark";
          nixdExtras = {
            nixpkgs = nixpkgs.outPath;
          };
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
          # neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;
        };
        categories = {
          markdown = true;
          general = true;
          custom = true;
          neonixdev = true;
          lint = true;
          format = true;
          test = true;
          lspDebugMode = false;
          themer = true;
          colorscheme = "catppuccin";
          nixdExtras = {
            # note, use outPath here instead of just
            # putting the derivation. otherwise,
            # nix would try to evaluate the entire nixpkgs.
            nixpkgs = nixpkgs.outPath;
          };
          theBestCat = "says meow!!";
          # yes even tortured inputs work.
          theWorstCat = {
            thing'1 = [ "MEOW" '']]' ]=][=[HISSS]]"[['' ];
            thing2 = [
              {
                thing3 = [ "give" "treat" ];
              }
              "I LOVE KEYBOARDS"
              (utils.mkLuaInline ''[[I am a]] .. [[ lua ]] .. type("value")'')
            ];
            thing4 = "couch is for scratching";
          };
        };
      };
    };

    defaultPackageName = "nixCats";
    # I did not here, but you might want to create a package named nvim.
    # If you make one of these packages be named nvim, you will get an nvim.desktop file
    # regardless of if it is the default or not.

    # defaultPackageName is also passed to utils.mkNixosModules and utils.mkHomeModules
    # and it controls the name of the top level option set.
    # If you made a package named `nvim` your default package,
    # the modules generated would be set at:
    # config.nvim = { enable = true; <see :h nixCats.module for options> }
  in
  # you shouldnt need to change much past here, but you can if you wish.
  # but you should at least eventually try to figure out whats going on here!
  # see :help nixCats.flake.outputs.exports
  forEachSystem (system: let
    # and this will be our builder! it takes a name from our packageDefinitions as an argument, and builds an nvim.
    nixCatsBuilder = utils.baseBuilder luaPath {
      # we pass in the things to make a pkgs variable to build nvim with later
      inherit nixpkgs system dependencyOverlays extra_pkg_config;
      # and also our categoryDefinitions and packageDefinitions
    } categoryDefinitions packageDefinitions;

    defaultPackage = nixCatsBuilder defaultPackageName;

    # this pkgs variable is just for using utils such as pkgs.mkShell
    # within this outputs set.
    pkgs = import nixpkgs { inherit system; };
    # The one used to build neovim is resolved inside the builder
    # and is passed to our categoryDefinitions and packageDefinitions
  in {
    # these outputs will be wrapped with ${system} by utils.eachSystem

    # this will make a package out of each of the packageDefinitions defined above
    # and set the default package to the one passed in here.
    packages = utils.mkAllWithDefault defaultPackage;

    # choose your package for devShell
    # and add whatever else you want in it.
    devShells = {
      default = pkgs.mkShell {
        name = defaultPackageName;
        packages = [ defaultPackage ];
        inputsFrom = [ ];
        shellHook = ''
        '';
      };
    };

  }) // {

    # now we can export some things that can be imported in other
    # flakes, WITHOUT needing to use a system variable to do it.
    # and update them into the rest of the outputs returned by the
    # eachDefaultSystem function.
    # these outputs will be NOT wrapped with ${system}

    # this will make an overlay out of each of the packageDefinitions defined above
    # and set the default overlay to the one named here.
    overlays = utils.makeOverlays luaPath {
      inherit nixpkgs dependencyOverlays extra_pkg_config;
    } categoryDefinitions packageDefinitions defaultPackageName;

    # we also export a nixos module to allow configuration from configuration.nix
    nixosModules.default = utils.mkNixosModules {
      inherit defaultPackageName dependencyOverlays luaPath
        categoryDefinitions packageDefinitions extra_pkg_config nixpkgs;
    };
    # and the same for home manager
    homeModule = utils.mkHomeModules {
      inherit defaultPackageName dependencyOverlays luaPath
        categoryDefinitions packageDefinitions extra_pkg_config nixpkgs;
    };
    inherit utils;
    inherit (utils) templates;
  };

}
