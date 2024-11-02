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
      testnames = {
        hello = true;
        pluginfile = true;
        afterplugin = true;
        test_libT_vars = true;
      };
    };
  in /*bash*/ ''
    ${runpkgbash}
  '';
}
