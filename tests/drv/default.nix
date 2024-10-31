{ inputs, stdenv, package, utils, libT, ... }:
stdenv.mkDerivation {
  name = "itbuilds";
  src = ./.;
  doCheck = true;
  dontUnpack = true;
  buildPhase = ''
    mkdir -p $out
  '';
  checkPhase = let
    runpkgbash = libT.mkRunPkgTest {
      inherit package;
      extraCategories = pkgs: {
        nix_test_info = {
          hello = "world";
        };
      };
    };
  in /*bash*/ ''
    ${runpkgbash}
  '';
}
