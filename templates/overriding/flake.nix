{
  description = ''
    all available arguments to override:
    luaPath categoryDefinitions packageDefinitions name
    nixpkgs system extra_pkg_config dependencyOverlays nixCats_passthru;

    This template shows how to reconfigure an already configured package
    without simply overwriting it and starting from scratch.
    Any package based on nixCats is a full nixCats.

    It also shows you how to make an appimage out of a nvim config as a bonus
  '';
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim?dir=templates/example";
    nixCats.inputs.nixpkgs.follows = "nixpkgs";
    # we are going to modify the example nixCats config to export
    # an appimage using this bunder tool.
    nix-appimage.url = "github:ralismark/nix-appimage";
  };
  outputs = { self, nixpkgs, nixCats, nix-appimage, ... }@inputs: let
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
      inherit (OGpkg) utils;

      withExtraOverlays = OGpkg.override (prev: {
        # These next lines could be omitted. They are here for illustration
        # you COULD overide them, but we did not here.
        # we chose to inherit them from the main example config.
        inherit (prev) luaPath;
        inherit (prev) nixpkgs;
        inherit (prev) system;
        inherit (prev) extra_pkg_config;
        inherit (prev) nixCats_passthru;

        dependencyOverlays = prev.dependencyOverlays ++ [
          (utils.standardPluginOverlay inputs)
          # any other flake overlays here.
        ];
      });

      # you can call override many times. We could have also have done this all in 1 call.
      withExtraCats = withExtraOverlays.override (prev: {
        # add some new stuff, we update into the old categoryDefinitions our new values
        # to replace all, just dont call utils.mergeCatDefs
        categoryDefinitions = utils.mergeCatDefs prev.categoryDefinitions ({ pkgs, settings, categories, extra, name, mkNvimPlugin, ... }@packageDef: {
          # We do this with utils.mergeCatDefs
          # and now we can add some more stuff.
          lspsAndRuntimeDeps = with pkgs; {
            appimage = [
              # We include these extra dependencies so that our AppImage will always have what it needs.
              # The appimage is not sandboxed from the path.
              # However it has its own internal /nix directory.
              # This means it cannot see packages that were installed
              # globally via nix specifically, but it will find things installed via other package managers.
              # since the main reason to use the AppImage is when you
              # cannot use nix at all, this ends up not being an issue.
              coreutils-full
              xclip
              wl-clipboard
              git
              nix
              curl
            ];
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
          #     if vim.fn.filereadable(newCfgDir .. "/init.lua") == 1 then
          #       dofile(newCfgDir .. "/init.lua")
          #     elseif vim.fn.filereadable(newCfgDir .. "/init.vim") == 1 then
          #       vim.cmd.source(newCfgDir .. "/init.vim")
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
          newvim = utils.mergeCatDefs prev.packageDefinitions.nixCats ({ pkgs, ... }: {
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
          });
          # this is the package we are going to build into an appimage
          appCats = utils.mergeCatDefs prev.packageDefinitions.nixCats ({pkgs , ... }: {
            categories = {
              # include our new category
              # with the extra dependencies needed for the appimage version.
              appimage = true;
            };
          });
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
    # as you can see, from running :NixCats pawsible in the newvim package,
    # built by running `nix build .#newvim` or `nix build .`
    # you now have a copy of the nixCats example config,
    # but with an added mini-nvim!
    # You also have some other packages at varying stages of being overridden.
    # each override call produces a new package with the new changes.

    # nix build .#app-images.x86_64-linux.default
    app-images = forSystems (system: {
      # and use the bunder to make an appimage out of the appCats package!
      default = nix-appimage.bundlers.${system}.default (self.packages.${system}.default.override { name = "appCats"; });
    });
  };
}
