# Changelog

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
