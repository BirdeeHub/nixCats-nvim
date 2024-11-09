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
    isMain = package.nixCats_packageName == "nixCats";
    testname = if isMain then "hello_example_config" else "hello_lazy.nvim_example";
    finalpackage = package.override (prev: {
      categoryDefinitions = utils.mergeCatDefs prev.categoryDefinitions ({ pkgs, settings, categories, name, ... }@packageDef: {
        lspsAndRuntimeDeps = {
          kickstarttestcfg = [
            pkgs.git
          ];
        };
        optionalLuaAdditions = {
          extratestconfig = /*lua*/''
            make_test("${testname}", function()
              assert(require('nixCats').cats.nixCats_packageName == [[${package.nixCats_packageName}]])
            end)
          '';
        };
      });
      packageDefinitions = prev.packageDefinitions // {
        ${package.nixCats_packageName} = utils.mergeCatDefs prev.packageDefinitions.${package.nixCats_packageName} ({ pkgs, ... }: {
          categories = {
            extratestconfig = true;
            kickstarttestcfg = ! isMain;
          };
        });
      };
    });
    # you can define multiple test runs within a single test phase.
    # if you need a clean environment:
    # define 2 of these with different tests, and run them both in the check phase
    runpkgbash = libT.mkRunPkgTest {
      package = finalpackage;
      testnames = {
        ${testname} = true;
      };
    };
  in /*bash*/ ''
    ${runpkgbash}
  '';
}
