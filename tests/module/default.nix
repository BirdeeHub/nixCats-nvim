{ inputs, testvim, utils, stdenv, ... }: let
in stdenv.mkDerivation {
  name = "libfuncs";
  src = ./.;
  doCheck = true;
  dontUnpack = true;
  buildPhase = ''
    mkdir -p $out
  '';
  checkPhase = let
  in ''
  '';
}
