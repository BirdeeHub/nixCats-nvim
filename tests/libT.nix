{ pkgs
  , inputs
  , testvim
  , system
  , utils
  , ...
}: with builtins; rec {
  mkHMmodulePkgs = {
    username ? "REPLACE_ME"
    , entrymodule ? ./main.nix
    , ...
  }: let
    hmcfg = inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [ entrymodule testvim.homeModule ];
      extraSpecialArgs = {
        packagename = testvim.nixCats_packageName;
        inherit
          username
          testvim
          inputs
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
          ;
      };
    };
  in nixoscfg.config.testvim.out;
}
