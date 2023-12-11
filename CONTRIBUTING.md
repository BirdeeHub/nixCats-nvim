Post to discussions about any debuggers or other things with build steps not on nixpkgs,

so that others may easily import that debugger/lsp/dependency/whatever they've been wanting as well!

The main drawback to using nix for nvim is when the thing is not on nixpkgs and has a hard build step.

So, again, when you figure a derivation out, regardless of what nvim related thing it is, post it to discussions!!!

Basically, there are some debuggers that are on mason and not on nixpkgs and thus do not work on nixOS.
To build them you would need to make an overlay with a derivation for it inside. If you figure it out post the overlay to discussions.

---

Please let me know about any nix options or features or improvements I should find a way to add to the scheme!

I would especially like someone more experienced than me in the exact load order of noevim
to help me ensure that it loads as accurately as possible.

It loads in what I think is the correct order,
however, I would like verification beyond my ability to read neovim documentation.

If it is not accurate, this would be fixable without changing the interface for flake.nix,
but I cannot fix what I do not know is broken.

All loading of the config folder is defined
in nix/builder/default.nix, and all wrapping is done in nix/builder/wrapNeovim.nix, called by the builder/default.nix file.

---

I will not be making lua changes outside of possibly adding borders to popup windows because the lua is really not the point of this repository.

I am unsure if I should add flake-compat or not.

Let me know if there is anything else I am missing!

I am still new to nix and do not yet know all the options available to me.
