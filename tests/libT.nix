{ pkgs
  , lib
  , stdenv
  , inputs
  , testvim
  , system
  , nix
  , utils
  , stateVersion
  , ...
}: with builtins; rec {
  mkHMmodulePkgs = {
    username ? "REPLACE_ME"
    , entrymodule ? ./main.nix
    , ...
  }: let
    hmcfg = inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        entrymodule
        testvim.homeModule
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
      extraSpecialArgs = {
        packagename = testvim.nixCats_packageName;
        inherit
          username
          testvim
          inputs
          utils
          ;
      };
    };
  in hmcfg.config.testvim.out;

  mkNixOSmodulePkgs = {
    username ? "REPLACE_ME"
    , hostname ? "HOSTLESS"
    , entrymodule ? ./main.nix
    , ...
  }: let
    nixoscfg = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [ entrymodule testvim.nixosModule ];
      specialArgs = {
        packagename = testvim.nixCats_packageName;
        inherit
          inputs
          hostname
          testvim
          username
          utils
          ;
      };
    };
  in nixoscfg.config.testvim.out;
}
