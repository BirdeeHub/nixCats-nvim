{
  description = ''
    all available arguments to override:
    luaPath categoryDefinitions packageDefinitions name
    nixpkgs system extra_pkg_config dependencyOverlays nixCats_passthru;

    This template shows how to reconfigure an already configured package
    without simply overwriting it and starting from scratch.

    Any package based on nixCats is a full nixCats.
  '';
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";
    nixCats.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { nixpkgs, nixCats, ... }@inputs: let
    # we are using a different forEachSystem for only 1 output.
    # rather than the full flake-utils function.
    # This is because I decided to only demonstrate outputting packages for this template,
    # to keep the focus on the overriding.
    forSystems = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all;
  in {
    # you could fill out the rest of the flake spec, here we are only exporting packages.
    # as you can see, thats really all you need anyway.
    # the following will output to packages.${system}.{ our packages }
    packages = forSystems (system:
      let

      # NOTE: we will be using only this 1 package from the nixCats repo from here on.
      # This technique works ANYWHERE you can get a nixCats based package.
      OGpkg = nixCats.packages.${system}.default;

      # we can even get our utils from it.
      inherit (OGpkg.passthru) utils;

      withExtraOverlays = OGpkg.override (prev: {
        # These next lines could be omitted. They are here for illustration
        # you COULD overide them, but we did not here.
        # we chose to inherit them from the main example config.
        inherit (prev) luaPath;
        inherit (prev) nixpkgs;
        inherit (prev) system;
        inherit (prev) extra_pkg_config;
        inherit (prev) nixCats_passthru;

        # and our dependencyOverlays by system.
        # we didnt add any extra here but this is to demonstrate
        # that it is the same as any other templates,
        # we are just using a different function to iterate over systems
        # to show more possibilities. it outputs to:
        # dependencyOverlays.${system} = somelistofoverlays;
        # just like normal.
        dependencyOverlays = forSystems (system: [
          (utils.mergeOverlayLists prev.dependencyOverlays.${system} [
            (utils.standardPluginOverlay inputs)
            # any other flake overlays here.
          ])
        ]);
        # NOTE: or to replace:
        # dependencyOverlays = forSystems (system: [
        #   (utils.standardPluginOverlay inputs)
        # ]);
      });

      # you can call override many times. We could have also have done this all in 1 call.
      withExtraCats = withExtraOverlays.override (prev: {
        # add some new stuff, we update into the old categoryDefinitions our new values
        # to replace all, just dont call utils.mergeCatDefs
        categoryDefinitions = utils.mergeCatDefs prev.categoryDefinitions ({ pkgs, settings, categories, name, ... }@packageDef: {
          # We do this with utils.mergeCatDefs
          # and now we can add some more stuff.
          lspsAndRuntimeDeps = with pkgs; {
            newcat = [ hello ];
          };
          startupPlugins = with pkgs.vimPlugins; {
            newcat = [
              # yes the home manager syntax also works in nixCats
              # its just only really useful when making quick modifications.
              # normally we already have a whole config directory to put it in.
              { plugin = mini-nvim;
                type = "lua";
                config = /*lua*/''
                  require('mini.surround').setup()
                '';
              }

            ];
          };
          # you could also source the current directory ON TOP of the one in luaPath.
          # if you want to make it also respect wrapRc, you can access the value
          # of wrapRc in the settings set provided to the function.
          # optionalLuaAdditions = {
          #   newcat = let
          #     newDir = if settings.wrapRc then
          #       "${./.}" else
          #       "/path/to/here";
          #   in /*lua*/''
          #     local newCfgDir = [[${newDir}]]
          #     vim.opt.packpath:prepend(newCfgDir)
          #     vim.opt.runtimepath:prepend(newCfgDir)
          #     vim.opt.runtimepath:append(newCfgDir .. "/after")
          #     if vim.fn.filereadable(newCfgDir .. "/init.vim") == 1 then
          #       vim.cmd.source(newCfgDir .. "/init.vim")
          #     end
          #     if vim.fn.filereadable(newCfgDir .. "/init.lua") == 1 then
          #       dofile(newCfgDir .. "/init.lua")
          #     end
          #   '';
          # };
          # see :h nixCats.flake.outputs.categories for the available sets in categoryDefinitions
        });
      });
      # and we can override again and add packageDefinitions this time
      # If we already had the categories we wanted defined, and only wanted to enable them,
      # we could override just the package definitions and enable them!
      withExtraPkgDefs = withExtraCats.override (prev: {
        # If you were starting from scratch, you would replace instead.
        packageDefinitions = prev.packageDefinitions // {
          # we merge the new definitions into
          # the prev.packageDefinitions.nixCats package 
          # which was in the original packageDefinitions set.
          newvim = (utils.mergeCatDefs prev.packageDefinitions.nixCats ({ pkgs, ... }: {
            settings = {
              # these ones override the old ones
              aliases = [ "nvi" ];
            };
            categories = {
              # enable our new category
              newcat = true;
              # remember, the others are still here!
              # We merged, rather than overwriting them.
              # You can see all of them with `:NixCats cats` in your editor!
            };
          }));
        };
      });
      # and choose the name of the package you want to build
      finalPackageNew = withExtraPkgDefs.override (prev: {
        name = "newvim";
      });
      # we merged so this one is still available too!
      finalPackageOld = withExtraPkgDefs.override (prev: {
        name = "nixCats";
      });

    # the final outputs
    in {
      # every stage above produces a package you could output.
      # you dont have to export them all, again, this is for demonstration.
      default = finalPackageNew;
      newvim = finalPackageNew;
      nixCats = finalPackageOld;
      inherit withExtraCats withExtraOverlays withExtraPkgDefs OGpkg;
    });
    # as you can see, from running :NixCats pawsible and :!hello in the newvim package,
    # built by running `nix build .#newvim` or `nix build .`
    # you now have a copy of the nixCats example config,
    # but with an added mini-nvim and gnu hello!
    # You also have some other packages at varying stages of being overridden.
    # each override call produces a new package with the new changes.
  };
}
