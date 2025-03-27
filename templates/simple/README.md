# Simple

This is approximately the most minimal configuration that can be called a fully-featured configuration,
and is split up into multiple files for easy reading.
(Of course, everyone has their own take on what minimal truly means...)

Just like the [`flakeless`](../flakeless) template it is a nix expression that returns a derivation containing
neovim plus your configuration that can be installed like any other package.

This configuration does not make much use of the category system. Everything is in 1 single `general` category.

It does not lazily load its plugins.

It does not set up backup download methods when not using nix.

If you are new to nvim and lua and maybe even nix, and everything else is too confusing, this may help!

You can run `nix-build` on it,

or import it from any nix code like

`import ./thisdir { inherit pkgs; inherit (inputs) nixCats; }`

or even like this if you are using an impure configuration or the repl

`import ./thisdir {}`

You could make it into a flake too!

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";
  };
  outputs = { self, nixpkgs, nixCats, ... }@inputs: {
    packages = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all (system: let
        pkgs = import nixpkgs { inherit system; overlays = []; config = {}; };
    in nixCats.utils.mkAllWithDefault (import ./. (inputs // { inherit pkgs; })));
    homeModule = self.packages.x86_64-linux.default.homeModule; # <- it will get the system from the importing configuration
    nixosModule = self.packages.x86_64-linux.default.nixosModule; # <- module namespace defaults to defaultPackageName.{ enable, packageNames, etc... }
  };
}
```
