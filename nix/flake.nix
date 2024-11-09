{
  outputs = { ... }: let
    utils = import ../.;
  in {
    utils = builtins.trace ''
      Deprecation warning: github:BirdeeHub/nixCats-nvim?dir=nix flake input is being deprecated.
      Please use github:BirdeeHub/nixCats-nvim instead.
      This flake input will be removed before 2025
    '' utils;
    templates = builtins.trace ''
      Deprecation warning: github:BirdeeHub/nixCats-nvim?dir=nix flake input is being deprecated.
      Please use github:BirdeeHub/nixCats-nvim instead.
      This flake input will be removed before 2025
    '' utils.templates;
  };
}
