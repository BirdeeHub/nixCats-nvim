{
  description = ''
    This flake can be imported with the flake reference

    inputs.nixCats.url = "github:BirdeeHub/nixCats-nvim?dir=nix";

    inputs.nixCats.url = "github:BirdeeHub/nixCats-nvim/<ref_or_rev>?dir=nix";

    If you want to drop even the nixpkgs input of nixCats,
    you may import this instead.

    It does not export modules or packages of its own because those need nixpkgs.

    However, it exports everything required for the default template,
    and the nixExpressionFlakeOutputs template.
    Which will still be able to output everything,
    including its own modules, overlays and packages.
  '';
  outputs = { ... }: let
    utils = import ./.;
  in {
    # everything is in utils.
    inherit utils;
    inherit (utils) templates;
  };
}
