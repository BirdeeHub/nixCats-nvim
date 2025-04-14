{
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
    lspsAndRuntimeDeps = {
      general = with pkgs; [
        lazygit
        lua-language-server
        stylua
        nixd
        alejandra
      ];
    };

    # This is for plugins that will load at startup without using packadd:
    startupPlugins = {
      general = with pkgs.vimPlugins; [
        snacks-nvim
        onedark-nvim
        vim-sleuth
        mini-ai
        mini-icons
        mini-pairs
        nvim-lspconfig
        vim-startuptime
        blink-cmp
        nvim-treesitter.withAllGrammars
        lualine-nvim
        lualine-lsp-progress
        gitsigns-nvim
        which-key-nvim
        nvim-lint
        conform-nvim
        nvim-dap
        nvim-dap-ui
        nvim-dap-virtual-text
      ];
    };

    # not loaded automatically at startup.
    # use with packadd and an autocommand in config to achieve lazy loading
    optionalPlugins = {
      general = with pkgs.vimPlugins; [
        lazydev-nvim
      ];
    };
  };

  # see :help nixCats.flake.outputs.packageDefinitions
  packageDefinitions = {
    # These are the names of your packages
    # you can include as many as you wish.
    # each of these sets are also written into the nixCats plugin for querying within lua.
    nvim = {pkgs, name, mkPlugin, ... }: {
      settings = {
        suffix-path = true;
        suffix-LD = true;
        # see :help nixCats.flake.outputs.settings
        # IMPORTANT:
        # your aliases may not conflict with other packages.
        # aliases = [ "vim" ];
        hosts.python3.enable = false;
        hosts.node.enable = false;
        hosts.ruby.enable = false;
        hosts.perl.enable = false;
      };
      # and a set of categories that you want
      # All categories you wish to include must be marked true
      categories = {
        general = true;
      };
      # anything else to pass and grab in lua with `nixCats.extra`
      extra = {};
    };
  };

  # We will build the one named nvim here and export that one.
  defaultPackageName = "nvim";

# return our package!
in utils.baseBuilder luaPath { inherit pkgs; } categoryDefinitions packageDefinitions defaultPackageName
# NOTE: or to return a set of all of them:
# `in utils.mkAllPackages (utils.baseBuilder luaPath { inherit pkgs; } categoryDefinitions packageDefinitions defaultPackageName)`

# NOTE: you may call .overrideNixCats on the resulting package or packages
# to construct different packages from
# your packageDefinitions from the resulting derivation of this expression!
# `finalPackage.overrideNixCats { name = "aDifferentPackage"; }`
# see :h nixCats.overriding
