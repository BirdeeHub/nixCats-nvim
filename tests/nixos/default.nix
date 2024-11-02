{ stdenv, inputs, package, utils, libT, ... }: let
  modulevim = (libT.mkNixOSmodulePkgs {
    package = package;
    entrymodule = ./main.nix;
  }).packages.${package.nixCats_packageName};
in stdenv.mkDerivation {
  name = "nixosmodulebuilds";
  src = modulevim;
  doCheck = true;
  dontUnpack = true;
  buildPhase = ''
    mkdir -p $out
  '';
  checkPhase = let
    runpkgcmd = libT.mkRunPkgTest {
      package = modulevim;
      testnames = {
        hello = true;
        lua_dir = true;
        pluginfile = true;
        afterplugin = true;
        test_libT_vars = true;
        nested_test = true;
      };
    };
  in /*bash*/ ''
    ${runpkgcmd}
  '';
}
