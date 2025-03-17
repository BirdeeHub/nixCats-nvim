### How to help

- Share your nixCats-based configurations in [discussions](https://github.com/BirdeeHub/nixCats-nvim/discussions)!!

- If you have any questions that you don't think are bugs, please post them in [discussions](https://github.com/BirdeeHub/nixCats-nvim/discussions) so that others may benefit from any answers in the future.

- Help with docs and readme! I find writing docs hard.
  Being clear in writing and getting your point across is an art.

- If you suspect a bug, please leave an [issue](https://github.com/BirdeeHub/nixCats-nvim/issues) (or a PR if you know what it is) so that we can address it.

- Improving and standardising the [templates](./templates).

- Adding more [tests](#tests).

See below sections for more details.
Any other contributions and fixes are also welcome.

All code for nixCats is in these places: [utils](./utils) and [builder](./builder) and [luaUtils](./templates/luaUtils/lua/nixCatsUtils).
(with the exception of [default.nix](./templates/default.nix) in the templates directory)

All tests are in [tests](./tests)

And all docs are either in [nixCatsHelp](./nixCatsHelp), or generated from Nix files, or [templates](./templates).

Thank you!!!

All commits should be named following [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/)

This ensures that the release-please bot can then make a release for it if needed.

---

### Documentation

The in-editor help is defined in [nixCatsHelp](./nixCatsHelp).

The [nixCats website](https://nixcats.org) is [automatically generated](https://github.com/BirdeeHub/nixCats-doc) from the help files and the main readme.
The README is converted using Pandoc and GitHub Flavored Markdown.

- Any updates only need to be made here.

- If anyone knows how to make the little warning and info things from GitHub work with Pandoc, that would be great too.

- In order to work on both GitHub and the website, all links in the README must be full URLs.

- The site generation for the in-editor docs will look exactly how it does in the editor,
and helptag links will work.

The in-editor docs are generated into html using a nixCats neovim package.

Yes, you heard that right. As I said, they will look exactly how they do in the editor.

Some other docs such as the templates, nix utils, and module helps are generated from the code via other techniques such as nix-doc

These other docs are generated into markdown and then pandoc converts them to html.

### Templates

I would like to drastically improve the help and templates for modules,
and encourage most people to set up nixCats either as a module or a separate flake.

But I am not sure the best way to explain how to export
the result of a module from your system flake so you can run it via `nix run`

You can grab it from your config set via `self` in the flake.
You can find it in the REPL, under nixCats.out.packages in the correct config set.

```nix
self.homeConfigurations."<home_config_name>".config."<defaultPackageName>".out.packages."<package_name>"
```

The reason I am having trouble explaining this, is because you can change the module namespace of the nixCats options.

It could be at `self.homeConfigurations."<home_config_name>".config.mysupercoolmodules.my-neovim.out.packages.<packagename>` or whatever.

Or even `self.legacyPackages.x86_64-linux.homeConfigurations."<home_config_name>".config.mysupercoolmodules.my-neovim.out.packages.<packagename>`.

It's a cool feature but how do I explain that now...

The module namespace can be set when you call `utils.mkNixosModules` or `utils.mkHomeModules`

and how to grab it from your config depends on where your config gets exported from your flake.

I welcome any help in making this happen.

- The [kickstart-nvim](./templates/kickstart-nvim) template should remain as-is until someone comes up with a better way to explain the lazy wrapper other than
  > `grep` for this and read about the ten places it's different.

### Tests

Run the tests with
```sh
nix flake check --show-trace -Lv ./tests
```

I will slowly be adding tests to the tests directory.
If anyone would like to add some tests, please do!

#### Suggested workflow for writing tests

1. Write a test in the test nvim config at [./tests/nvim](./tests/nvim)

   To do this, add whatever dependencies you need to the `default.nix` file,
   then in Lua use
   ```lua
   make_test("name", function() assert.True(condition) end)
   ```
   using the assert library from `luassert` to write tests.
   Anywhere that nvim will run it is fine, but writing the tests in
   a new file the plugin directory is the easiest.

2. To run the test, either create a new `nix check` derivation or add to an existing one.

   Inside that derivation, you must use the following to create a script that runs the tests:

   ```nix
     mkRunPkgTest = {
       package,
       packagename ? package.nixCats_packageName,
       runnable_name ? packagename,
       runnable_is_nvim ? true,
       preRunBash ? "",
       testnames ? {},
       ...
     }:
   ```
   This will make a command to run the set of tests.
   Include this in the `checkPhase` of the `nix check` derivation.

   It will add the testing library to the package passed in,
   and including `testname = true` in the `testnames` set will schedule that
   test to be ran within that run of `nvim --headless`.

All config added to the test nvim config should be done within `if nixCats('category') then`
checks so that it can be enabled for specific tests only.

There are two functions for creating packages based on the module form for testing modules.

`lib.mkNixOSmodulePkgs` takes `{ package, entrymodule }`

`lib.mkHMmodulePkgs` takes `{ package, entrymodule, stateVersion ? "24.05", username = "REPLACE_ME" }`

These will give you `config.${defaultPackageName}.out.packages` containing the resulting packages from the module.
The nixos form also includes `config.${defaultPackageName}.out.users.<USERNAME>.packages`.

- The `entrymodule` in the home module test form has access to all the modules in Home Manager,
although they won't be evaluated, so things like setting `home.sessionVariables` won't show up in the test.

- The `entrymodule` in the NixOS module test form does not have access to the default set of modules,
as it has to use `lib.evalModules` to build without making a whole machine,
so if you want to use outside modules you will have to import them, or define dummy options.

Like the Home Manager modules, you can use the config values they set and they will contain the expected values,
but they otherwise will not be evaluated and will not show up in the test.

#### Troubleshooting

If a test is scheduled to be ran that does not exist,
or an error is thrown that causes a scheduled test not to be ran,
the `checkPhase` will hang indefinitely.

So if this happens, cancel it and define the test, or if it was defined,
you know that an uncaught failure occurred OUTSIDE of the tests themselves,
which prevented a scheduled test from being defined.

To prevent this as much as possible, if you want to use the lua directory for config outside of a test definition,
you should do it inside of [tests/nvim/lua/config](./tests/nvim/lua/config), because this directory is wrapped
in a `pcall`, and if it errors or not is reported by `lua_dir` test.
