# Changelog

## [7.3.2](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.3.1...v7.3.2) (2025-11-04)


### Bug Fixes

* **deprecated_pkgs.system:** nixpkgs is deprecating pkgs.system ([360f9d3](https://github.com/BirdeeHub/nixCats-nvim/commit/360f9d39d2aa438ebc0bba4a51a473e236d4ecaf))

## [7.3.1](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.3.0...v7.3.1) (2025-10-29)


### Bug Fixes

* **deprecated:** runCommandNoCC -&gt; runCommand ([45b354d](https://github.com/BirdeeHub/nixCats-nvim/commit/45b354d0ae63bc0c57e1728f1a8edf2a5e84bd52))

## [7.3.0](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.2.16...v7.3.0) (2025-09-12)


### Features

* **wrappedCfgPath:** new setting and args for packageDefinitions ([ad1da96](https://github.com/BirdeeHub/nixCats-nvim/commit/ad1da962e23dfa5bdfd59b2b0b85603a16609848))

## [7.2.16](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.2.15...v7.2.16) (2025-06-20)


### Bug Fixes

* **example_template:** blink+luasnip cancel active snippet correctly ([c6000fb](https://github.com/BirdeeHub/nixCats-nvim/commit/c6000fb730d4067e3e1d65e9d5a2cbcd1ceaef83))

## [7.2.15](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.2.14...v7.2.15) (2025-06-11)


### Bug Fixes

* **deprecations:** Remove all functions and behaviors with deprecation warnings ([425b179](https://github.com/BirdeeHub/nixCats-nvim/commit/425b179bee4150166ab2b25efcc6a78898c64373))

## [7.2.14](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.2.13...v7.2.14) (2025-06-01)


### Bug Fixes

* **detnix:** n2l now automatically handles the builtins.path { path } buisness ([753ab0f](https://github.com/BirdeeHub/nixCats-nvim/commit/753ab0f11b3097d6e3a5e4f5b4f2ff9bfb9d3b36))

## [7.2.13](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.2.12...v7.2.13) (2025-04-29)


### Bug Fixes

* **wrapper:** nixpkgs changed neovim maintainers attribute to teams ([#289](https://github.com/BirdeeHub/nixCats-nvim/issues/289)) ([434628a](https://github.com/BirdeeHub/nixCats-nvim/commit/434628aa657da87b1db69461c687ee874307d565))

## [7.2.12](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.2.11...v7.2.12) (2025-04-29)


### Bug Fixes

* **n2l:** added n2l.toUnpacked, which turns a list into a comma separated string of lua values ([e7478d0](https://github.com/BirdeeHub/nixCats-nvim/commit/e7478d0e522d50f9d0e830f3a0f7027914e44d85))

## [7.2.11](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.2.10...v7.2.11) (2025-04-27)


### Bug Fixes

* **docs:** docs for new feature ([5380e1a](https://github.com/BirdeeHub/nixCats-nvim/commit/5380e1a6d4db3e8163a6ffce25d1e9fc8da20196))

## [7.2.10](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.2.9...v7.2.10) (2025-04-27)


### Bug Fixes

* **builder:** see latest refactor ([8df6e65](https://github.com/BirdeeHub/nixCats-nvim/commit/8df6e65b22669118afec2ef31b0a2b9d7622d506))

## [7.2.9](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.2.8...v7.2.9) (2025-04-27)


### Bug Fixes

* **module:** fix minor bug introduced in last refactor ([d9b30fe](https://github.com/BirdeeHub/nixCats-nvim/commit/d9b30fe42fba2e7f324409f462d4b04c52a51d3c))

## [7.2.8](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.2.7...v7.2.8) (2025-04-21)


### Bug Fixes

* **spec_deps:** fixed a bug where drv.passthru.value would seem like a spec ([cc46310](https://github.com/BirdeeHub/nixCats-nvim/commit/cc46310c6351bc5078b469b48cd6827109059934))

## [7.2.7](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.2.6...v7.2.7) (2025-04-20)


### Bug Fixes

* **lua_plugin:** incorrect use of package.preload on some rarely used values ([53940b5](https://github.com/BirdeeHub/nixCats-nvim/commit/53940b5f42a9e1a14db3f4cf895a741dbc47945f))

## [7.2.6](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.2.5...v7.2.6) (2025-04-20)


### Bug Fixes

* **lsps_and_libs:** minor feature, can specify prefix or suffix individually ([c11f477](https://github.com/BirdeeHub/nixCats-nvim/commit/c11f47779c2873eb9e14476680b298074f035b43))

## [7.2.5](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.2.4...v7.2.5) (2025-04-20)


### Bug Fixes

* **templates:** converting templates to new lsp scheme for 0.11 ([#252](https://github.com/BirdeeHub/nixCats-nvim/issues/252)) ([6cb25b1](https://github.com/BirdeeHub/nixCats-nvim/commit/6cb25b1c003283332bf1a62cd2bb938f9e2cd9f8))

## [7.2.4](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.2.3...v7.2.4) (2025-04-17)


### Bug Fixes

* **home-manager:** fix multi install regression from latest fix ([0787a77](https://github.com/BirdeeHub/nixCats-nvim/commit/0787a77b0d375733ec5213e224258a8b675e658a))

## [7.2.3](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.2.2...v7.2.3) (2025-04-17)


### Bug Fixes

* **tmux-resurrect:** https://github.com/BirdeeHub/nixCats-nvim/issues/244 ([9021ee6](https://github.com/BirdeeHub/nixCats-nvim/commit/9021ee6f85892588511135512b10e5d9f2cb9e9d))

## [7.2.2](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.2.1...v7.2.2) (2025-04-13)


### Bug Fixes

* **host_deps:** pluginAttr error messages now properly match that of its associated libraries category section ([5cbda76](https://github.com/BirdeeHub/nixCats-nvim/commit/5cbda76bf285ef9da3b7d45a857e7ec364555207))

## [7.2.1](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.2.0...v7.2.1) (2025-04-13)


### Bug Fixes

* **host_deps:** grabbing host deps from plugins properly accepts function items ([624c018](https://github.com/BirdeeHub/nixCats-nvim/commit/624c01824b9c246ea3a05bbdc0ba9c04f7447dbc))

## [7.2.0](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.1.2...v7.2.0) (2025-04-12)


### Features

* **wrapArgs:** added spec form for setting priority if desired ([6c2fc3d](https://github.com/BirdeeHub/nixCats-nvim/commit/6c2fc3df598fae20cfca9ab1891a37e999c935a9))

## [7.1.2](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.1.1...v7.1.2) (2025-04-08)


### Performance Improvements

* **init:** all rtp searches removed from init sequence ([85626fc](https://github.com/BirdeeHub/nixCats-nvim/commit/85626fc1338d5f7205955c048f0f24a360a5655a))

## [7.1.1](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.1.0...v7.1.1) (2025-04-06)


### Bug Fixes

* **petShop:** minor issue with petShop display when redefining default hosts ([a6194f9](https://github.com/BirdeeHub/nixCats-nvim/commit/a6194f9cc2104443ee82694dfac93c698397419b))

## [7.1.0](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.0.7...v7.1.0) (2025-04-06)


### Features

* **petShop:** `:NixCats petShop` debug command now actually shows useful info! ([822eacc](https://github.com/BirdeeHub/nixCats-nvim/commit/822eacc693d1363ef74b26a13f252fece473a498))

## [7.0.7](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.0.6...v7.0.7) (2025-04-05)


### Performance Improvements

* **nixCats:** lua/nixCats/init.lua to lua/nixCats.lua for earlier search path position ([d595a68](https://github.com/BirdeeHub/nixCats-nvim/commit/d595a687101a011018ca854e2098ef5968d8154b))

## [7.0.6](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.0.5...v7.0.6) (2025-04-04)


### Bug Fixes

* **bashb4:** bashBeforeWrapper section didnt allow use of ${placeholder "out"} ([f4c53a9](https://github.com/BirdeeHub/nixCats-nvim/commit/f4c53a9f3c14b0a86845e13f5dfb6c747ae14ef8))

## [7.0.5](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.0.4...v7.0.5) (2025-04-04)


### Bug Fixes

* **VIMINIT:** -u didnt let us, but actually, we can support  itself too ([f0f081d](https://github.com/BirdeeHub/nixCats-nvim/commit/f0f081d84f574f6c3d7c511099cdc7d06dde4766))

## [7.0.4](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.0.3...v7.0.4) (2025-04-04)


### Bug Fixes

* **hosts:** path.args was not applied without also using extraWrapperArgs ([2be5129](https://github.com/BirdeeHub/nixCats-nvim/commit/2be5129c0cbec3ed0477029091d6f036d52578a3))

## [7.0.3](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.0.2...v7.0.3) (2025-04-03)


### Bug Fixes

* **collate_grammars:** fix regression when value is false ([843a0ee](https://github.com/BirdeeHub/nixCats-nvim/commit/843a0ee71389923cc30e4c31a7ec8fcdc130e209))

## [7.0.2](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.0.1...v7.0.2) (2025-04-03)


### Bug Fixes

* **hosts:** explicit disable not disabling healthchecks ([3957745](https://github.com/BirdeeHub/nixCats-nvim/commit/395774590f186a6ac8b996631ece9aa0e1164d10))

## [7.0.1](https://github.com/BirdeeHub/nixCats-nvim/compare/v7.0.0...v7.0.1) (2025-04-03)


### Bug Fixes

* **hosts:** path not always properly removed ([72560e4](https://github.com/BirdeeHub/nixCats-nvim/commit/72560e46f0a48ed7de4d9bf1c0261d1cc203b634))

## [6.10.0](https://github.com/BirdeeHub/nixCats-nvim/compare/v6.9.3...v6.10.0) (2025-04-03)


### Features

* **providers:** hosting program update, now can bundle anything with nvim ([#197](https://github.com/BirdeeHub/nixCats-nvim/issues/197)) ([2aa1b64](https://github.com/BirdeeHub/nixCats-nvim/commit/2aa1b646de7af1f17ce0a7eb2f7bf6ca1cfb0cc4))

## [6.9.3](https://github.com/BirdeeHub/nixCats-nvim/compare/v6.9.2...v6.9.3) (2025-04-01)


### Bug Fixes

* **lix:** lix doesnt have builtins.warn ([32c97d9](https://github.com/BirdeeHub/nixCats-nvim/commit/32c97d95bd5ccb86ebd977b4987e127e0fb498a2))

## [6.9.2](https://github.com/BirdeeHub/nixCats-nvim/compare/v6.9.1...v6.9.2) (2025-04-01)


### Performance Improvements

* **nixCats_plugin:** entire plugin inlined (minor performance benefits) ([d8ea184](https://github.com/BirdeeHub/nixCats-nvim/commit/d8ea18412e66e35e7214ac838833110128802a59))

## [6.9.1](https://github.com/BirdeeHub/nixCats-nvim/compare/v6.9.0...v6.9.1) (2025-04-01)


### Bug Fixes

* **overrideAttrs:** nativeBuildInputs and prefersLocalBuild ([227bc60](https://github.com/BirdeeHub/nixCats-nvim/commit/227bc60dcca3bd243effa7bbeb4c27c28c8122f8))

## [6.9.0](https://github.com/BirdeeHub/nixCats-nvim/compare/v6.8.0...v6.9.0) (2025-03-31)


### Features

* **wrapRc:** allowed toggling of wrapRc at runtime via setting a custom env var ([85ab39e](https://github.com/BirdeeHub/nixCats-nvim/commit/85ab39ecd0f3b8cf95cd1f4e136ee579eae367ca))

## [6.8.0](https://github.com/BirdeeHub/nixCats-nvim/compare/v6.7.0...v6.8.0) (2025-03-31)


### Features

* **vim.o.exrc:** support vim.o.exrc despite wrapping the config with -u ([cc2360f](https://github.com/BirdeeHub/nixCats-nvim/commit/cc2360fa34ce982786363424744273bb255ef2bf))


### Bug Fixes

* **vim.o.exrc:** support vim.o.exrc despite wrapping the config ([1d40e7f](https://github.com/BirdeeHub/nixCats-nvim/commit/1d40e7fed19e7b3e46465bf2a7a5941773739c7a))

## [6.7.0](https://github.com/BirdeeHub/nixCats-nvim/compare/v6.6.8...v6.7.0) (2025-03-31)


### Features

* **optionalLuaCats:** values within categories of optionalLuaPreInit and optionalLuaAdditions can now specify priority ([a2293ed](https://github.com/BirdeeHub/nixCats-nvim/commit/a2293ed392c7013f8f567481434131e3b6c675f6))

## [6.6.8](https://github.com/BirdeeHub/nixCats-nvim/compare/v6.6.7...v6.6.8) (2025-03-30)


### Bug Fixes

* **sensible_defaults:** suffix-path and suffix-LD now default to true ([06d616e](https://github.com/BirdeeHub/nixCats-nvim/commit/06d616e09bffef8bb0efae9dbd92d9984988489b))

## [6.6.7](https://github.com/BirdeeHub/nixCats-nvim/compare/v6.6.6...v6.6.7) (2025-03-30)


### Bug Fixes

* **builder:** prevent UpdateRemotePlugins from running user config during build ([4d33792](https://github.com/BirdeeHub/nixCats-nvim/commit/4d33792c3163609f4617a19615a4b7431bdbf08e))

## [6.6.6](https://github.com/BirdeeHub/nixCats-nvim/compare/v6.6.5...v6.6.6) (2025-03-30)


### Bug Fixes

* **builder:** desktop file fix would be different on mac ([48d48e6](https://github.com/BirdeeHub/nixCats-nvim/commit/48d48e6f4830e8c0d8a285890da349e8edbc89d2))

## [6.6.5](https://github.com/BirdeeHub/nixCats-nvim/compare/v6.6.4...v6.6.5) (2025-03-30)


### Bug Fixes

* **builder:** nvim nightly changed its desktop file, we change how we fix desktop file ([3d337bd](https://github.com/BirdeeHub/nixCats-nvim/commit/3d337bdf2e060cec4a29bbbbc86d9ecbe4051be1))

## [6.6.4](https://github.com/BirdeeHub/nixCats-nvim/compare/v6.6.3...v6.6.4) (2025-03-29)


### Bug Fixes

* **nixpkgs_deps:** dependencies declared by nixpkgs plugins can no longer override user provided ones with the same name ([738915d](https://github.com/BirdeeHub/nixCats-nvim/commit/738915d5933fe16236fca89ec1bf77967b4a8932))

## [6.6.3](https://github.com/BirdeeHub/nixCats-nvim/compare/v6.6.2...v6.6.3) (2025-03-28)


### Bug Fixes

* **mkPlugin:** mkPlugin = name: src: added (because mkNvimPlugin = src: name: is backwards) ([a91d721](https://github.com/BirdeeHub/nixCats-nvim/commit/a91d721747fcdf502bbaad53bc9b0c1ecc61d660))

## [6.6.2](https://github.com/BirdeeHub/nixCats-nvim/compare/v6.6.1...v6.6.2) (2025-03-28)


### Bug Fixes

* **autoPluginOverlay:** autoPluginOverlay no longer entirely overrides old autoPluginOverlay ([40c942b](https://github.com/BirdeeHub/nixCats-nvim/commit/40c942b51f59686a32ad17f15f8aa52b222aea53))

## [6.6.1](https://github.com/BirdeeHub/nixCats-nvim/compare/v6.6.0...v6.6.1) (2025-03-20)


### Bug Fixes

* **nixCats.packageBinPath:** now set regardless of useage of bashBeforeWrapper category section ([0040179](https://github.com/BirdeeHub/nixCats-nvim/commit/0040179e705fcc04c2f858ff815a90f52a9948ca))

## [6.6.0](https://github.com/BirdeeHub/nixCats-nvim/compare/v6.5.1...v6.6.0) (2025-03-19)


### Features

* **extraCats:** when field added in addition to cond ([#152](https://github.com/BirdeeHub/nixCats-nvim/issues/152)) ([bb13576](https://github.com/BirdeeHub/nixCats-nvim/commit/bb13576f1c91c0c1178935c6332322248abd86dc))

## [6.5.1](https://github.com/BirdeeHub/nixCats-nvim/compare/v6.5.0...v6.5.1) (2025-03-18)


### Bug Fixes

* **utils_utils:** various flake output constructors updated, same behavior ([339dc4a](https://github.com/BirdeeHub/nixCats-nvim/commit/339dc4a4d5fd34b9039922b709b301cbf318610a))

## [6.5.0](https://github.com/BirdeeHub/nixCats-nvim/compare/v6.4.0...v6.5.0) (2025-03-17)


### Features

* **overrides and pkgs:** see below ([#132](https://github.com/BirdeeHub/nixCats-nvim/issues/132)) ([1bc1e66](https://github.com/BirdeeHub/nixCats-nvim/commit/1bc1e666ac7619b540a6030e1255c12c87218d52))

## [6.4.0](https://github.com/BirdeeHub/nixCats-nvim/compare/v6.3.1...v6.4.0) (2025-03-14)


### Features

* **autoconf:** autoconfigure and autowrapRuntimeDeps support to match pkgs.wrapNeovim ([#127](https://github.com/BirdeeHub/nixCats-nvim/issues/127)) ([a7eb442](https://github.com/BirdeeHub/nixCats-nvim/commit/a7eb442b9c925dc02bd2a30203b16039d0b0a86e))

## [6.3.1](https://github.com/BirdeeHub/nixCats-nvim/compare/v6.3.0...v6.3.1) (2025-03-13)


### Bug Fixes

* **nixCatsUtils.lzUtils.for_cat:** Wow... How... Nevermind... just copy the new one if you used it ([ad8d22d](https://github.com/BirdeeHub/nixCats-nvim/commit/ad8d22d086cfb7a1cb0e9fda1fb871bbe370c942))
* **unwrappedCfgPath:** lua inline types now allowed ([1083985](https://github.com/BirdeeHub/nixCats-nvim/commit/1083985e7db43bf50ae0606890d17c6f3b1816fd))
