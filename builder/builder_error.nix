# Copyright (c) 2023 BirdeeHub 
# Licensed under the MIT license 
builtins.throw ''
Error calling main nixCats builder function `utils.baseBuilder`

# -------------------------------------------------------- #

# Arguments

## **luaPath** (`path` or `stringWithContext`)
STORE PATH to your `~/.config/nvim` replacement.

## **pkgsParams** (`AttrSet`)
set of items for building the pkgs that builds your neovim.

accepted attributes are:

- `nixpkgs` (`path` | `input` | `channel`)
: required unless using `pkgs`
: allows path, or flake input

- `system` (`string`)
: required unless using `pkgs`
: or using --impure argument

- `pkgs` (`channel`)
: can be passed instead of `nixpkgs` and `system`
: the resulting nvim will inherit overlays and other such modifications of the `pkgs` value

- `dependencyOverlays` (`listOf overlays` | `null`)
: default = null

- `extra_pkg_config` (`AttrSet`)
: default = {}
: the attrset passed to:
: `import nixpkgs { config = extra_pkg_config; inherit system; }`

- `extra_pkg_params` (`AttrSet`)
: default = {}
: `import nixpkgs (extra_pkg_params // { inherit system; })`

- `nixCats_passthru` (`AttrSet`)
: default = {}
: attrset of extra stuff for finalPackage.passthru

## **categoryDefinitions** (`functionTo` `AttrSet`)
type: function that returns set of sets of categories of dependencies.
Called with the contents of the current package definition as arguments

```nix
{ pkgs, settings, categories, extra, name, mkPlugin, ... }@packageDef: {
  lspsAndRuntimeDeps = {
    general = with pkgs; [ ];
  };
  startupPlugins = {
    general = with pkgs.vimPlugins; [ ];
    some_other_name = [];
  };
  # ...
}
```

see :h [nixCats.flake.outputs.categories](https://nixcats.org/nixCats_format.html#nixCats.flake.outputs.categories)

## **packageDefinitions** (`AttrsOf` `functionTo` `AttrSet`)
set of functions that each represent the settings and included categories for a package.

Among other info, things declared in settings, categories, and extra will be available in lua.

```nix
{
  nvim = { pkgs, mkPlugin, ... }: {
    settings = {};
    categories = {
      general = true;
      some_other_name = true;
    };
    extra = {};
  };
}
```

see :h [nixCats.flake.outputs.packageDefinitions](https://nixcats.org/nixCats_format.html#nixCats.flake.outputs.packageDefinitions)

see :h [nixCats.flake.outputs.settings](https://nixcats.org/nixCats_format.html#nixCats.flake.outputs.settings)

## **name** (`string`)
name of the package to build from `packageDefinitions`

# Note:

When using override, all values shown above will
be top level attributes of prev, none will be nested.

i.e. `finalPackage.override (prev: { inherit (prev) dependencyOverlays; })`

NOT `prev.pkgsParams.dependencyOverlays` or something like that

---
''
