{ stdenv, inputs, package, utils, libT, ... }: let
  modulevimout = (libT.mkNixOSmodulePkgs {
    package = package;
    entrymodule = ./main.nix;
  });
  modulevim = modulevimout.packages.${package.nixCats_packageName};
  usermodulevim = modulevimout.users.testuser.packages.${package.nixCats_packageName};
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
        nixCats_fields = true;
        extraCats = true;
      };
    };
    runuserpkgcmd = libT.mkRunPkgTest {
      package = usermodulevim;
      testnames = {
        hello = true;
        lua_dir = true;
        pluginfile = true;
        afterplugin = true;
        test_libT_vars = true;
        nested_test = true;
        nixCats_fields = true;
        extraCats = true;
      };
    };
  in /*bash*/ ''
    ${runpkgcmd}
    ${runuserpkgcmd}
  '';
}
