# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license
{
main = builtins.throw ''
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
'';

optLua = name: builtins.throw ''
Invalid syntax in ${name}:
Both optionalLuaPreInit or optionalLuaAdditions have the same syntax,
one runs before the ''${luaPath}/init.lua, the other after:

Useage:
optionalLuaPreInit = {
  catname = [ #<- a list
    { # <- of sets
      priority = 0; # default priority is 150
      config = "vim.loader.enable()";
    }
    "vim.g.mycustomval = 5" #<- or strings
  ];
}
Both also accept a plain string at the cost of merging not being effective with such a value
optionalLuaAdditions = "print('init.lua has finished running')";
'';

extraCats = builtins.throw ''
# ERROR: incorrect extraCats syntax in categoryDefinitions:
# USAGE:
# see: :help nixCats.flake.outputs.categoryDefinitions.default_values
extraCats = {
  # if target.cat is enabled, the list of extra cats is active!
  target.cat = [ # <- must be a list of (sets or list of strings)
    # list representing attribute path of category to enable.
    [ "to" "enable" ]
    # or as a set
    {
      cat = [ "other" "toenable" ]; #<- required if providing the set form
      # all below conditions, if provided, must be true for the `cat` to be included

      # true if any containing category of the listed cats are enabled
      when = [ # <- `when` conditions must be a list of list of strings
        [ "another" "cat" ]
      ];
      # true if any containing OR sub category of the listed cats are enabled
      cond = [ # <- `cond`-itions must be a list of list of strings
        [ "other" "category" ]
      ];
    }
  ];
};
'';

catsOfFn = name: builtins.throw ''
Error: Invalid syntax in categoryDefinitions.
${name}.libraries category section does not accept functions!
'';

wrapArgs = name: builtins.throw ''
Error: Invalid syntax in categoryDefinitions.
${if name != "wrapperArgs" then name + "." else ""}wrapperArgs categories must be
either a list of:
  (lists of strings like [ "--set" "MYVAR" "test value" ])
  or (sets with { value = [ "--set" "MYVAR" "test value" ]; priority = 150; })
or they may be a list of only strings.
lib.escapeShellArgs will be called on the resulting list of arguments
If you don't know what these are, check this link out:
https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
'';

xtraWrapArgs = name: builtins.throw ''
Error: Invalid syntax in categoryDefinitions.
${if name != "extraWrapperArgs" && name != "bashBeforeWrapper" then name + ".extraWrapperArgs" else name} categories must be
a list of strings, or sets with { value = "${if name != "bashBeforeWrapper" then "--set MYVAR 'test value'" else "some bash code"}"; priority = 150; }
THESE VALUES WILL BE PASSED UNESCAPED
${if name != "bashBeforeWrapper" then ''
If you don't know what these are, check this link out:
https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
'' else ""}
'';

envVar = name: let
  sname = if name == "environmentVariables" then name else "${name}.envVars";
in builtins.throw ''
Error: Invalid syntax in categoryDefinitions.
Useage for ${sname} category section is:
${sname} = {
  test = {
    CATTESTVARDEFAULT = "It worked!";
  };
  moretests = {
    subtest1 = {
      CATTESTVAR = "hehehe";
    };
    subtest2 = {
      CATTESTVAR3 = "Hello World!";
    };
  };
};
'';

hosts = name: val: type: builtins.throw ''
Error: Invalid syntax in nixCats settings hosts.${name}.${val}
hosts.${name}.${val} must be a ${type}
categoryDefinitions = { pkgs, settings, categories, name, ... }@packageDef: {
  ${name} = {
    wrapperArgs = {};
    libraries = {};
    envVars = {};
    extraWrapperArgs = {};
  };
}
hosts = {
  ${name} = {
    enable = true; # <- default false

    # REQUIRED:
    # path can be { value = pkgs.python3; args = [ "extra" "wrapper" "args" ]; nvimArgs = [ "for" "nvim" "itself" ]; }
    # or a string, or a function that returns either type.
    # If not a function, the ${name}.libraries categoryDefinitions section is ignored
    path = depfn: (${name}.withPackages depfn).interpreter;

    # REQUIRED:
    # the vim.g variable to set to the path of the host.
    global = "${name}_host_prog"; # <- the default value

    # grabs the named attribute from all included plugins, valid only if path is a function,
    # included dependencies are returned by the
    # function your path function recieves in addition to items from ${name}.libraries
    pluginAttr = "${name}Dependencies"; # <- defaults to null

    # If explicitely disabled, will set this vim.g variable to 0
    # This is for disabling healthchecks for a provider.
    # Variable only set if host.${name}.enable = false
    # can be set to null to prevent it from being set regardless of enable value
    disabled = "loaded_${name}_provider"; # <- the default value
  };
};
'';

hostPath = name: builtins.throw ''
nixCats: hosts.${name}.path is required to use hosts.${name}
hosts.${name}.path may be:
- a string or path to executable
- a set with
  {
    value = string or path to executable;
    args = [ "wrapper" "args" "for" "host" ];
    nvimArgs = [ "wrapper" "args" "for" "neovim" ];
  }
- a function that recieves a function that returns a list of dependencies which returns either of the above.

If `path` is a function, a ${name}.libraries section in categoryDefinitions
is created in addition to the normal ${name}.wrapperArgs, ${name}.extraWrapperArgs, ${name}.envVars sections.

The function that gets passed to `path` recieves either null, or a different value, and returns a list of packages from
${name}.libraries.

If you pass it null, the ${name}.libraries categoryDefinitions section
accepts only lists, and if you pass it a value, the section may contain functions as well
in the style of lua.withPackages, where the functions are called with the value passed.

# examples:
hosts.perl.path = depfn: "''${perl.withPackages (p: depfn p ++ [ p.NeovimExt p.Appcpanminus ])}/bin/perl";

hosts.python.path = depfn: {
  value = (python3.withPackages (p: depfn p ++ [p.pynvim])).interpreter;
  args = [ "--unset" "PYTHONPATH" ];
};

hosts.ruby.path = let
  rubyEnv = pkgs.bundlerEnv {
    name = "neovim-ruby-env";
    postBuild = "ln -sf ''${pkgs.ruby}/bin/* $out/bin";
    gemdir = ./your/gem/dir;
  };
in {
  value = "''${rubyEnv}/bin/neovim-ruby-host";
  nvimArgs = [ "--set" "GEM_HOME" "''${rubyEnv}/''${rubyEnv.ruby.gemPath}" "--suffix" "PATH" ":" "''${rubyEnv}/bin" ];
};
'';
}
