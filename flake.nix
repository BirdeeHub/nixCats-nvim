# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license
# Only 3 files are marked with this header.
# Please leave them in.
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
    "plugins-fidget" = {
      url = "github:j-hui/fidget.nvim/legacy";
      flake = false;
    };
    # a flake import. We will import this one with an overlay
    # but you could also import the package itself instead.
    # overlays are just nice if they are offered.
    nixd.url = "github:nix-community/nixd";
  };

  # see :help nixCats.flake.outputs
  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    # This line makes this package availeable for all systems
    # ("x86_64-linux", "aarch64-linux", "i686-linux", "x86_64-darwin",...)
    flake-utils.lib.eachDefaultSystem (system: let
      utils = (import ./builder/utils.nix).utils;

      # see :help nixCats.flake.outputs.overlays
      # This overlay grabs all the inputs named in the format
      # `plugins-<pluginName>`
      # Once we add this overlay to our nixpkgs, we are able to
      # use `pkgs.neovimPlugins`, which is a set of our plugins.
      # we will import it separaly from the others
      # so we can export it separately from the flake.
      standardPluginOverlay = utils.standardPluginOverlay;
      # you may define more overlays in the overlays directory, and import them
      # in the default.nix file in that directory just like customBuildsOverlay.
      # `pkgs.nixCatsBuilds` is a set of plugins defined in that file.
      # see overlays/default.nix for how to add more overlays in that directory.
      # or see :help nixCats.flake.nixperts.overlays
      otherOverlays = (import ./overlays inputs) ++ [
        # add any flake overlays here.
        inputs.nixd.overlays.default
      ];
      pkgs = import nixpkgs {
        inherit system;
        overlays = otherOverlays ++ 
          [ (standardPluginOverlay inputs) ];
        # config.allowUnfree = true;
      };

      # Now that our plugin inputs/overlays and pkgs have been defined,
      # We define a function to facilitate package building for particular categories
      # to do this it imports ./builder/default.nix, passing it our information.
      # This allows us to define categories and settings for or package later and then choose a package.

      # see :help nixCats.flake.outputs.builder
      baseBuilder = import ./builder "${self}/nixCatsHelp";
      nixCatsBuilder = baseBuilder self pkgs
        # notice how it doesn't care that these are defined lower in the file?
        categoryDefinitions packageDefinitions;

      # see :help nixCats.flake.outputs.categories
      categoryDefinitions = name: {
        # to define and use a new category, simply add a new list to a set here, 
        # and later, you will include categoryname = true; in the set you
        # provide when you build the package using this builder function.
        # see :help nixCats.flake.outputs.packaging for info on that section.

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
          neonixdev = with pkgs; [
            # nix-doc tags will make your tags much better in nix
            # but only if you have nil as well for some reason
            nix-doc
            nil
            lua-language-server
            nixd
          ];
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
          markdown = with pkgs.nixCatsBuilds; [
            markdown-preview-nvim
          ];
          gitPlugins = with pkgs.neovimPlugins; [
            hlargs
            fidget
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
            # other
            nvim-lspconfig
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
          themer = with pkgs.vimPlugins; [
            # You can retreive information from the
            # packageDefinitions of the package this was packaged with.
            # you can use it to create something like subcategories
            # that could still be set by customPackager
            (builtins.getAttr packageDefinitions.${name}.categories.colorscheme {
                # Theme switcher without creating a new category
                "onedark" = onedark-vim;
                "catppuccin" = catppuccin-nvim;
                "catppuccin-mocha" = catppuccin-nvim;
                "tokyonight" = tokyonight-nvim;
                "tokyonight-day" = tokyonight-nvim;
              }
            )
          ];
        };

        # not loaded automatically at startup.
        # use with packadd in config to achieve something like lazy loading
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

        extraPythonPackages = {
          test = [ (_:[]) ];
        };
        extraPython3Packages = {
          test = [ (_:[]) ];
        };
        extraLuaPackages = {
          test = [ (_:[]) ];
        };
      };

      # see :help nixCats.flake.outputs.settings
      settings = {
        nixCats = {
          wrapRc = true;
          configDirName = "nixCats-nvim";
          viAlias = false;
          vimAlias = true;
        };
        unwrappedLua = {
          wrapRc = false;
          # will now look for nixCats-nvim within .config and .local and others
          configDirName = "nixCats-nvim";
          viAlias = false;
          vimAlias = true;
        };
      };


      # And then build a package with specific categories from above here:
      # All categories you wish to include must be marked true,
      # but false may be omitted.
      # This entire set is also passed to nixCats for querying within the lua.
      # It is passed as a Lua table with values name = boolean. same as here.

      # see :help nixCats.flake.outputs.packageDefinitions
      packageDefinitions = {
        nixCats = {
          settings = settings.nixCats; 
          categories = {
            generalBuildInputs = true;
            markdown = true;
            gitPlugins = true;
            general = true;
            custom = true;
            neonixdev = true;
            test = true;
            debug = false;
            # this does not have an associated category of plugins, 
            # but lua can still check for it
            lspDebugMode = false;
            # you could also pass something else:
            themer = true;
            colorscheme = "onedark";
            theWorstCat = {
              thing1 = [ "MEOW" "HISSS" ];
              thing2 = [
                {
                  thing3 = [ "give" "treat" ];
                }
                "I LOVE KEYBOARDS"
              ];
              thing4 = "couch is for scratching";
            };
            # you could :lua print(vim.inspect(require('nixCats').theWorstCat))
            # I got carried away and it worked FIRST TRY.
            # see :help nixCats
          };
        };
        regularCats = { 
          settings = settings.unwrappedLua;
          categories = {
            generalBuildInputs = true;
            markdown = true;
            gitPlugins = true;
            general = true;
            custom = true;
            neonixdev = true;
            debug = false;
            test = true;
            lspDebugMode = false;
            themer = true;
            colorscheme = "catppuccin";
            theWorstCat = {
              thing1 = [ "MEOW" "HISSS" ];
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
      customPackager = baseBuilder self pkgs categoryDefinitions;

      # You may use these to modify some or all of your categoryDefinitions
      customBuilders = {
        fresh = baseBuilder;
        keepLua = baseBuilder self;
      };

      inherit otherOverlays;
      inherit categoryDefinitions;
      inherit utils;

    }



  ); # end of flake utils, which returns the value of outputs
}
