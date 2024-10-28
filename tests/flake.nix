{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "path:../.";
    examplevim.url = "path:../templates/example";
    examplevim.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, nixCats, ... }@inputs: let
    forAllSys = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all;
  in {
    checks = forAllSys (system: let
      pkgs = import nixpkgs { inherit system; };
    in
    {
      default = pkgs.stdenv.mkDerivation {
        name = "catsWithDefault-1";
        src = ./.;
        doCheck = true;
        dontUnpack = true;
        buildPhase = ''
          mkdir -p $out
        '';
        checkPhase = ''
        '';
      };
    });
  };
}
