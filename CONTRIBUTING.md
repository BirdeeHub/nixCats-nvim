Post to discussions about any debuggers or other things with build steps not on nixpkgs,

so that others may easily import that debugger/lsp/dependency/whatever they've been wanting as well!

The main drawback to using nix for nvim is when the thing is not on nixpkgs and has a hard build step.

So, again, when you figure a derivation out, regardless of what nvim related thing it is, post it to discussions!!!

Basically there are some debuggers on mason but not on nixpkgs so if you figure out how to build them in nix post it!

---

Outside of that, clone or fork the repo and do as you please, 
but adding plugins and bells and whistles to main gets in the way of the kickstarter spirit.

There will be no major lua additions, outside of possibly adding borders to popup windows
because I've been told people like that. The lua is not the point of this repository.

---

My roadmap:

I will be adding a nixOS module that exports the same options but is configurable within
configuration.nix for both system and user.

Currently in a local branch I have system level options that work and user level options that don't,
so this will take me at least some amount of time to make in a satisfactory manner.

It will be generated in utils based on the existing scheme and exported in outputs of flake.nix, keeping impact on flake.nix as minimal as possible.

I will not be adding a module for home-manager,
because you can already import flakes in home-manager and thus use the normal scheme for configuring within importing flakes.

After adding the nixOS module, I will also be adding importable templates for several scenarios to provide easier use of the project.

When doing this, I will most likely be moving builder/ and nixCatsHelp/ into a single nix/ directory to keep the project root clean.

I will of course be updating help to match.

---

After that this repository will simply be recieving maintenance and be kept up to date with things like:

running nix flake update about once a week and fixing any breaking changes made to the current plugins.

My personal configuration imports the builder from this one straight from github so at the very least I am committed to running flake update every once in a while.
