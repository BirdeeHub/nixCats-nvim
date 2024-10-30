{ inputs, stdenv, testvim, ... }:
stdenv.mkDerivation {
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
        ${prev.name} = testvim.utils.mergeCatDefs prev.packageDefinitions.${prev.name} ({ pkgs, ... }: {
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
