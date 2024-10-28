{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "path:../.";
  };
  outputs = { self, nixpkgs, nixCats, ... }@inputs: let
    forAllSys = nixCats.utils.eachSystem nixpkgs.lib.platforms.all;
  in forAllSys (system: let
    pkgs = import nixpkgs { inherit system; };
  in
  {
    checks = {
      default = pkgs.stdenv.mkDerivation {
        name = "test-1";
        src = ./.;
        doCheck = true;
        dontUnpack = true;
        buildPhase = ''
          mkdir -p $out
        '';
        checkPhase = ''
        '';
      };
    };
  });
}
