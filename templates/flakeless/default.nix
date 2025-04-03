{ # NOTE: you may call .overrideNixCats (or .override if you don't use callPackage on this)
  # to construct different packages from
  # your packageDefinitions from the resulting derivation of this expression!
  # see :h nixCats.overriding
  # or build a set of all of them with `utils.mkAllPackages thedrv`
  pkgs ? import <nixpkgs> {}
  , nixCats ? builtins.fetchGit {
    url = "https://github.com/BirdeeHub/nixCats-nvim";
  }
  , ...
}: let
  # get the nixCats library with the builder function (and everything else) in it
  utils = import nixCats;
  # path to your new .config/nvim
  luaPath = ./.;

  # see :help nixCats.flake.outputs.categories
  categoryDefinitions = { pkgs, settings, categories, extra, name, mkPlugin, ... }@packageDef: {
    # to define and use a new category, simply add a new list to a set here, 
    # and later, you will include categoryname = true; in the set you
    # provide when you build the package using this builder function.
    # see :help nixCats.flake.outputs.packageDefinitions for info on that section.

    # lspsAndRuntimeDeps:
    # this section is for dependencies that should be available
    # at RUN TIME for plugins. Will be available to PATH within neovim terminal
    # this includes LSPs
    lspsAndRuntimeDeps = {
      general = with pkgs; [ ];
    };

    # This is for plugins that will load at startup without using packadd:
    startupPlugins = {
      general = with pkgs.vimPlugins; [ ];
    };

    # not loaded automatically at startup.
    # use with packadd and an autocommand in config to achieve lazy loading
    optionalPlugins = {
      general = with pkgs.vimPlugins; [ ];
    };

    # shared libraries to be added to LD_LIBRARY_PATH
    # variable available to nvim runtime
    sharedLibraries = {
      general = with pkgs; [ ];
    };

    # environmentVariables:
    # this section is for environmentVariables that should be available
    # at RUN TIME for plugins. Will be available to path within neovim terminal
    environmentVariables = {
      test = {
        CATTESTVAR = "It worked!";
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
    python3.libraries = {
      test = (_:[]);
    };
    # populates $LUA_PATH and $LUA_CPATH
    extraLuaPackages = {
      test = [ (_:[]) ];
    };
  };

  # And then build a package with specific categories from above here:
  # All categories you wish to include must be marked true,
  # but false may be omitted.
  # This entire set is also passed to nixCats for querying within the lua.

  # see :help nixCats.flake.outputs.packageDefinitions
  packageDefinitions = {
    # These are the names of your packages
    # you can include as many as you wish.
    nvim = {pkgs, name, mkPlugin, ... }: {
      # they contain a settings set defined above
      # see :help nixCats.flake.outputs.settings
      settings = {
        suffix-path = true;
        suffix-LD = true;
        wrapRc = true;
        # IMPORTANT:
        # your aliases may not conflict with your other packages.
        aliases = [ "vim" ];
        # neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;
      };
      # and a set of categories that you want
      categories = {
        general = true;
        test = true;
      };
      # anything else to pass and grab in lua with `nixCats.extra`
      extra = {};
    };
  };

  # We will build the one named nvim here and export that one.
  # you can change which package from packageDefinitions is built later
  # using package.override { name = "aDifferentPackage"; }
  defaultPackageName = "nvim";

# return our package!
in utils.baseBuilder luaPath { inherit pkgs; } categoryDefinitions packageDefinitions defaultPackageName
