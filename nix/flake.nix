{
  description = ''
    This flake can be imported with the flake reference

    inputs.nixCats.url = "github:BirdeeHub/nixCats-nvim?dir=nix";

    inputs.nixCats.url = "github:BirdeeHub/nixCats-nvim/<ref_or_rev>?dir=nix";

    If you want to drop even the nixpkgs dependency of nixCats,
    you may import this instead.

    It does not export modules or packages because those need nixpkgs.

    However, it exports everything required for the default template,
    and the nixExpressionFlakeOutputs template.
    Which will still be able to output everything,
    including its own modules, overlays and packages.

    If you import the module straight from nixCats,
    or use override directly on a nixCats package,
    this minimal version will not work, but everything
    required to build a package is still exported
    via this set.
  '';
  outputs = inputs: let
    utils = import ./.;
  in {
    # everything is in utils.
    inherit utils;
    inherit (utils) templates;
  };
}
