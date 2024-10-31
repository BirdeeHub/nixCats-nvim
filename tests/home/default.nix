{ stdenv, callPackage, inputs, package, utils, libT, stateVersion, ... }: let
  modulevim = (libT.mkHMmodulePkgs {
    package = package;
    inherit stateVersion;
    entrymodule = ./main.nix;
  }).packages.${package.nixCats_packageName};
in stdenv.mkDerivation {
  name = "modulebuilds";
  src = modulevim;
  doCheck = true;
  dontUnpack = true;
  buildPhase = ''
    mkdir -p $out
  '';
  checkPhase = let
    runpkgcmd = libT.mkRunPkgTest {
      package = modulevim;
      extraCategories = pkgs: {
        nix_test_info = {
          hello = "world";
        };
      };
    };
  in /*bash*/ ''
    ${runpkgcmd}
  '';
}
