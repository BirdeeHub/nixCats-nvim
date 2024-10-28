{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };
  outputs = { self, nixpkgs, ... }@inputs: let
    utils = import ../.;
    forAllSys = utils.eachSystem nixpkgs.lib.platforms.all;
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
    in utils.baseBuilder luaPath {
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
      default = self.checks.${system}.drv;
      drv = pkgs.stdenv.mkDerivation {
        name = "itbuilds";
        src = ./.;
        doCheck = true;
        dontUnpack = true;
        buildPhase = ''
          mkdir -p $out
        '';
        checkPhase = let
          drvtestvim = testvim.override (prev: {
            packageDefinitions = prev.packageDefinitions // {
              ${prev.name} = utils.mergeCatDefs prev.packageDefinitions.${prev.name} ({ pkgs, ... }: {
                settings = {
                };
                categories = {
                  nix_test_info = {
                    hello = "world";
                  };
                };
              });
            };
          });
        in /*bash*/ ''
          HOME=$(mktemp -d)
          TEST_TEMP=$(mktemp -d)
          mkdir -p $TEST_TEMP $HOME
          [ ! -f ${drvtestvim}/bin/testvim ] && exit 1 || echo "${drvtestvim}/bin/testvim exists!"
          ${drvtestvim}/bin/testvim --headless --cmd "lua vim.g.nix_test_out = [[$out]]; vim.g.nix_test_temp = [[$TEST_TEMP]]"
        '';
      };
    };
  });
}
