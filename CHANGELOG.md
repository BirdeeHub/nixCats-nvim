# Changelog

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
