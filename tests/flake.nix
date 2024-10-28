{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "path:../.";
  };
  outputs = { self, nixpkgs, nixCats, ... }@inputs: let
    forAllSys = nixCats.utils.eachSystem nixpkgs.lib.platforms.all;
    mkTestVim = system: let
      luaPath = ./.;
      dependencyOverlays = [
      ];
      categoryDefinitions = { pkgs, settings, categories, name, ... }@packageDef: {
      };
      packageDefinitions = {
        testvim = { pkgs, ... }: {
          settings = {
          };
          categories = {
            killAfter = true;
          };
        };
      };
    in nixCats.utils.baseBuilder luaPath {
        inherit nixpkgs system dependencyOverlays;
        extra_pkg_config = {
          allowUnfree = true;
        };
        nixCats_passthru = {};
      } categoryDefinitions packageDefinitions "testvim";
  in forAllSys (system: let
    pkgs = import nixpkgs { inherit system; };
    testvim = mkTestVim system;
  in
  {
    checks = {
      default = pkgs.stdenv.mkDerivation {
        name = "itbuilds";
        src = testvim;
        doCheck = true;
        dontUnpack = true;
        buildPhase = ''
          mkdir -p $out
        '';
        checkPhase = ''
          HOME=$(mktemp -d)
          [ ! -f $src/bin/testvim ] && exit 1 || echo "$src/bin/testvim exists!"
          ${testvim}/bin/testvim --headless --cmd "lua =require('nixCats')"
        '';
      };
    };
  });
}
