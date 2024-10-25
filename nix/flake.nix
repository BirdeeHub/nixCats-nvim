{
  outputs = { ... }: let
    utils = import ../.;
  in {
    # everything is in utils.
    utils = builtins.trace "Deprecation warning: github:BirdeeHub/nixCats-nvim?dir=nix flake input is being deprecated. Please use github:BirdeeHub/nixCats-nvim instead." utils;
    templates = builtins.trace "Deprecation warning: github:BirdeeHub/nixCats-nvim?dir=nix flake input is being deprecated. Please use github:BirdeeHub/nixCats-nvim instead." utils.templates;
  };
}
