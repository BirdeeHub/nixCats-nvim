# LazyVim Template for nixCats

How to get the [LazyVim](http://www.lazyvim.org/) distribution up and running

see the [kickstart-nvim template](../kickstart-nvim) for more info on the lazy wrapper or other utilities used.

## Important Considerations

This template provides a way to use LazyVim with nixCats, but there are several limitations and caveats to be aware of.

When running LazyVim in any Nix-based environment, unless the wrapper you use has already included all dependencies mason may need to install all LazyVim extras, every nix-based neovim solution will have similar limitations.

### 1. Mason Compatibility Issues
LazyVim is designed with the assumption that you are using `mason.nvim` to manage LSP servers and other dependencies. However, Mason installs precompiled binaries that may not be compatible with NixOS or other Nix-based systems. This can lead to missing or non-functional LSP servers unless handled properly.

#### Solutions:

- **Preferred:** Install LSP servers and dependencies via Nix. Add them to `lspsAndRuntimeDeps` to ensure they are properly available in your environment. In most cases, LazyVim will then load it correctly from your `PATH` via `nvim-lspconfig`, although it may still give a warning about missing `mason.nvim` or require some manual configuration.

- **Alternative:** If you are on a NixOS system and want to use Mason, you must manually ensure that all dependencies required by Mason-installed binaries are available. This can be difficult, but in situations where LazyVim only accepts mason, it can be the easier option.
- If you want to enable Mason, you will need to **uncomment the lines that disable it in your LazyVim configuration** and optionally add it to your startup plugins list in Nix.
- Then, if the lsp doesn't install correctly via mason, add dependencies to the `lspsAndRuntimeDeps` and `sharedLibraries` sections of your `categoryDefinitions` until it does.

If you AREN'T using NixOS, there is a reasonable chance that `mason.nvim` will not pose any issues for you.

So if you don't plan to use NixOS, you are fine to enable mason and leave it like that, although at that point, you should probably just be using LazyVim as-is.

### 2. LSP and Completion Issues
If LSPs and autocompletion do not work, verify the following:
- Run `:LspInfo` in Neovim to check if your LSP servers are detected and running.
- Ensure that all required LSP servers are installed via Nix or Mason (if enabled).
- Mason is either correctly enabled (if used) or completely disabled with all dependencies handled via Nix.
- If you are configuring LazyVim through `lazyvim.json`, try moving your extra plugin imports to your `lua` configuration instead.
  ```lua
  { 'LazyVim/LazyVim', import = 'lazyvim.plugins' },
  { import = "lazyvim.plugins.extras.lang.svelte" },
  { import = "lazyvim.plugins.extras.lang.tailwind" },
  ```

- Or make sure to set the location of the json file to your `nixCats.settings.unwrappedCfgPath` so that it can find and edit it (pointing it to the store would prevent lazy from editing it while using its UI extras interface).

### 3. LazyVim as a "Second-Class Citizen" in Nix
LazyVim is heavily integrated with `mason.nvim` and does not fully align with the Nix philosophy of declarative package management.

LazyVim also, obviously uses `lazy.nvim`. `lazy.nvim` technically works fine on with nix, HOWEVER it will block any other plugin manager, including nix, from installing anything on its own without also making a lazy.nvim plugin spec and making sure the names match. So, that is also less than ideal.

### 4. Alternative Approaches
If you find LazyVim too cumbersome to use with Nix, consider alternative configurations:
such as the one shown in the [example](../example) template using `lze`

If you wish to keep using `lazy.nvim` creating your own config based on the [kickstart-nvim](../kickstart-nvim) template will work better as you will have more control over whether mason is used.

However, again, `lazy.nvim` is not recommended for use with other package managers, including nix.

You will have a better experience using `lze` or `lz.n` to manage lazy loading with nix while making your own configuration.

## Conclusion
Using `LazyVim` with nix means you are prepared to debug potential compatibility issues due to LazyVim's reliance on Mason.
