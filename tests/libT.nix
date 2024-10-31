{
  inputs
  , pkgs
  , system
  , lib
  , stdenv
  , nix
  , utils
  , writeText
  , writeShellScript
  , ...
}: with builtins; rec {
  mkHMmodulePkgs = {
    package
    , stateVersion ? "24.05"
    , entrymodule ? ./main.nix
    , username ? "REPLACE_ME"
    , ...
  }: let
    packagename = package.nixCats_packageName;
    hmcfg = inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit
          packagename
          username
          package
          inputs
          utils
          ;
      };
      modules = [
        entrymodule
        package.homeModule
        ({ ... }: {
          home.username = username;
          home.homeDirectory = lib.mkDefault (let
            homeDirPrefix = if stdenv.hostPlatform.isDarwin then "Users" else "home";
          in "/${homeDirPrefix}/${username}");
          programs.home-manager.enable = true;
          nix.package = nix;
          home.stateVersion = stateVersion;
        })
      ];
    };
  in hmcfg.config.${packagename}.out;

  mkNixOSmodulePkgs = {
    package
    , entrymodule ? ./main.nix
    , stateVersion ? "24.05"
    , username ? "REPLACE_ME"
    , hostname ? "HOSTLESS"
    , ...
  }: let
    packagename = package.nixCats_packageName;
    nixoscfg = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit
          packagename
          inputs
          hostname
          package
          username
          utils
          ;
      };
      modules = [
        entrymodule
        package.nixosModule
      ];
    };
  in nixoscfg.config.${packagename}.out;

  mkRunPkgTest = {
    package,
    packagename ? package.nixCats_packageName,
    runnable_name ? packagename,
    preCfgLua ? "",
    preRunBash ? "",
    testnames ? {},
    ...
  }: let
    luaPre = writeText "luaPreCfg" preCfgLua;
    finaltestvim = package.override (prev: {
      packageDefinitions = prev.packageDefinitions // {
        ${packagename} = utils.mergeCatDefs prev.packageDefinitions.${packagename} ({ pkgs, ... }: {
          settings = {};
          categories = {
            nixCats_test_names = testnames;
          };
        });
      };
    });
  in writeShellScript "runtests-${packagename}-${runnable_name}" ''
    HOME="$(mktemp -d)"
    TEST_TEMP="$(mktemp -d)"
    mkdir -p "$TEST_TEMP" "$HOME"
    cd "$TEST_TEMP"
    [ ! -f "${finaltestvim}/bin/${runnable_name}" ] && \
      echo "${finaltestvim}/bin/${runnable_name} does not exist!" && exit 1
    ${preRunBash}
    "${finaltestvim}/bin/${runnable_name}" --headless \
    --cmd "lua vim.g.nix_test_out = [[$out]]; vim.g.nix_test_src = [[$src]]; vim.g.nix_test_temp = [[$TEST_TEMP]]; dofile('${luaPre}')"
  '';
}
