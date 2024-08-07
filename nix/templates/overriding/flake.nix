{
  description = ''
    all available arguments to override:
    luaPath categoryDefinitions packageDefinitions name
    nixpkgs system extra_pkg_config dependencyOverlays nixCats_passthru;

    While this template shows how to reconfigure an already configured package,
    To define an entirely new config, you would simply need to overwrite the values,
    rather than merging from the values from prev

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
    # also, this could be done just the same in a module with the final package added straight to home.packages
    # you could add the nixCats default overlay to your pkgs, and configure it entirely from pkgs.nixCats
    # you just need a nixCats package, any way you get it is fine.
  in {
    # you could fill out the rest of the flake spec, here we are only exporting packages.
    # as you can see, thats really all you need anyway.
    # the following will output to packages.${system}.{ our packages }
    packages = forSystems (system: let
      # NOTE: we will be using only this 1 package from the nixCats repo from here on.
      OGpkg = nixCats.packages.${system}.default;
      # we can even get our utils from it.
      inherit (OGpkg.passthru) utils;

      withExtraOverlays = OGpkg.override (prev: {
        # This line is unnecessary and simply for demonstration.
        inherit (prev) luaPath; # <-- we could overide it, but we did not here. 
        # The reason I did not is I didnt want to write yet another full lua config.

        # and our dependencyOverlays by system.
        # we didnt add any extra here but this is to demonstrate
        # that it is the same as any other template.
        # dependencyOverlays.${system} = somelistofoverlays;
        dependencyOverlays = forSystems (system: [
          (utils.mergeOverlayLists prev.dependencyOverlays.${system} [
            (utils.standardPluginOverlay inputs)
            # any other flake overlays here.
          ])
        ]);
        # or to replace
        # dependencyOverlays = forSystems (system: [
        #   (utils.standardPluginOverlay inputs)
        # ]);
      });

      # you can call override many times. We could have also have done this all in 1 call.
      withExtraCats = withExtraOverlays.override (prev: {
        # add some new stuff.
        categoryDefinitions = utils.mergeCatDefs prev.categoryDefinitions ({ pkgs, settings, categories, name, ... }@packageDef: {
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
          # you could also source the current directory ON TOP of the old one:
          # optionalLuaAdditions = {
          #   newcat = ''
          #     vim.opt.packpath:prepend("${./.}")
          #     vim.opt.runtimepath:prepend("${./.}")
          #     vim.opt.runtimepath:append("${./.}/after")
          #     dofile("${./.}/init.lua")
          #   '';
          # };
          # see :h nixCats.flake.outputs.categories for the available sets
        });
      });
      withExtraPkgDefs = withExtraCats.override (prev: {
        packageDefinitions = prev.packageDefinitions // {
          newvim = (utils.mergeCatDefs prev.packageDefinitions.nixCats ({ pkgs, ... }: {
            settings = {
              aliases = [ "nvi" ];
            };
            categories = {
              newcat = true;
            };
          }));
        };
      });

      finalPackageNew = withExtraPkgDefs.override (prev: {
        name = "newvim";
      });
      finalPackageOld = withExtraPkgDefs.override (prev: {
        name = "nixCats";
      });

    in {
      # every stage above produces a package you could output.
      default = finalPackageNew;
      newvim = finalPackageNew;
      nixCats = finalPackageOld;
      inherit withExtraCats withExtraOverlays withExtraPkgDefs;
    });
    # as you can see, from running :NixCats pawsible and :!hello in the newvim package,
    # built by running `nix build .#newvim` or `nix build .`
    # you now have a copy of the nixCats example config,
    # but with an added mini-nvim and gnu hello!
  };
}
