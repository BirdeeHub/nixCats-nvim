{ stdenv, callPackage, inputs, testvim, utils, ... }: let
    libT = callPackage ../libT.nix { inherit inputs testvim utils; };
    modulevim = (libT.mkHMmodulePkgs { username = "birdee"; entrymodule = ./main.nix; }).packages.testvim;
in stdenv.mkDerivation {
  name = "modulebuilds";
  src = modulevim;
  doCheck = true;
  dontUnpack = true;
  buildPhase = ''
    mkdir -p $out
  '';
  checkPhase = let
    drvtestvim = modulevim.override (prev: {
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
}
