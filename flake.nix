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

    "plugins-hlargs" = {
      url = "github:m-demare/hlargs.nvim";
      flake = false;
    };
    "plugins-harpoon" = {
      url = "github:ThePrimeagen/harpoon";
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
      # see :help nixCats.flake.outputs.overlays

      # Apply the overlays and load nixpkgs as `pkgs`
      # Once we add these overlays to our nixpkgs, we are able to
      # use `pkgs.neovimPlugins`, which is a set of our "plugins-pluginname" plugins,
      # or use `pkgs.customPlugins`, which is a set of our custom built plugins.
      overlays = (import ./overlays inputs) ++ [
        # add any flake overlays here.
        inputs.nixd.outputs.overlays.default
      ];
      pkgs = import nixpkgs {
        inherit system overlays;
        # config.allowUnfree = true;
      };

      # see :help nixCats.flake.outputs.builder

      # Now that our plugin inputs/overlays and pkgs have been defined,
      # We define a function to facilitate package building for particular categories
      # what that function does is it intakes a set of categories 
      # with a boolean value for each, and a set of settings
      # to do this it imports ./builder/default.nix, passing it our other information.
      # This allows us to define our categories and settings later.
      helpPath = "${self}/nixCatsHelp";
      nixVimBuilder = import ./builder helpPath self pkgs categoryDefinitions;

      categoryDefinitions = {
        # see :help nixCats.flake.outputs.builder
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
        # at RUN TIME for plugins. Will be available to path within neovim terminal
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
          markdown = with pkgs.customPlugins; [
            markdown-preview-nvim
          ];
          gitPlugins = with pkgs.neovimPlugins; [
            harpoon
            hlargs
            fidget
          ];
          general = with pkgs.vimPlugins; [
            # Theme
            onedark-vim
            # catppuccin-nvim
            # telescope
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
        };

        # not loaded automatically at startup.
        # use with packadd in config to achieve something like lazy loading
        optionalPlugins = {
          custom = with pkgs.customPlugins; [ ];
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

      # see :help nixCats.flake.outputs.packaging
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
          };
        };
      };
    in



    # see :help nixCats.flake.outputs.packages
    {
      # choose your default package
      packages = { default = (nixVimBuilder packageDefinitions.nixCats); }
        # this will add all packageDefinitions defined above
        // (builtins.mapAttrs (value: nixVimBuilder value) packageDefinitions);

      # choose your package for devShell
      # and whatever else you want in it.
      devShell = pkgs.mkShell {
        name = "nixCats.nvim";
        packages = [ (nixVimBuilder packageDefinitions.nixCats) ];
        inputsFrom = [ ];
        shellHook = ''
        '';
      };

      # this will make an overlay out of each of the packageDefinitions defined above
      overlays = let
        # choose the name and value of your defaultOverlayPackage
        defaultOverlayPackage = {
          name = "nixCats";
          value = packageDefinitions.nixCats;
        };
      in
      { default = (self: super: { ${defaultOverlayPackage.name} = nixVimBuilder defaultOverlayPackage.value; }); } 
      // (builtins.mapAttrs (name: value: (self: super: { ${name} = nixVimBuilder value; })) packageDefinitions);

      # To choose settings and categories from the flake that calls this flake.
      customPackager = nixVimBuilder;

      # The overlay that allows for auto import with plugins-pluginname
      standardPluginOverlay = import ./overlays/standardPluginOverlay.nix;
      # You may use these to modify some or all of your categoryDefinitions
      customBuilders = {
        # These 2 will still recieve the flake's lua when wrapRc = true;
        fresh = import ./builder helpPath self;
        merged = newPkgs: categoryDefs:
          (import ./builder helpPath self (pkgs // newPkgs) (categoryDefinitions // categoryDefs));
        # for these ones, you may specify a new path to lua that can be used with wrapRc = true
        newLuaPath = import ./builder helpPath;
        mergedNewLuaPath = path: newPkgs: categoryDefs:
          (import ./builder helpPath path (pkgs // newPkgs) (categoryDefinitions // categoryDefs));
      };
    }



  ); # end of flake utils, which returns the value of outputs
}
