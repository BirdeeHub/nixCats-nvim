{ system, inputs, utils, packagename, ... }: let
  luaPath = ./.;
  nixCats_passthru = {};
  extra_pkg_config = {
    allowUnfree = true;
  };
  dependencyOverlays = [
    (utils.standardPluginOverlay inputs)
  ];
  categoryDefinitions = { pkgs, settings, categories, name, ... }@packageDef: {
  };
  packageDefinitions = {
    ${packagename} = { pkgs, ... }: {
      settings = {
      };
      categories = {
      };
      extra = {
        typetests = rec {
          funcsafe_add = utils.n2l.types.function-safe.mk {
            args = [ "a" "b" ];
            body = /*lua*/''
              return a + b
            '';
          };
          funcunsafe_mult = utils.n2l.types.function-unsafe.mk {
            args = [ "a" "b" ];
            body = /*lua*/''
              return a * b
            '';
          };
          with_meta_call = utils.n2l.types.with-meta.mk (let
            tablevar = "tbl_in";
          in {
            table = {
              this = "is a test table";
              inatesttable = "that will be translated to a lua table with a metatable";
            };
            # to avoid translating the table multiple times,
            # define a variable name for it in lua. Defaults to "tbl_in"
            inherit tablevar;
            meta = {
              # __call in lua lets us also call it like a function
              __call = utils.n2l.types.function-unsafe.mk {
                args = [ "self" "..." ];
                body = ''
                  return ${tablevar}.this
                '';
              };
            };
          });
          inlinesafe1 = utils.n2l.types.inline-safe.mk ''${utils.n2l.resolve funcsafe_add}(1, 2)'';
          inlinesafe2 = utils.n2l.types.inline-safe.mk ''${utils.n2l.resolve funcunsafe_mult}(1, 2)'';
          inlineunsafe1 = utils.n2l.types.inline-unsafe.mk { body = ''${utils.n2l.resolve funcsafe_add}(1, 2)''; };
          inlineunsafe2 = utils.n2l.types.inline-unsafe.mk { body = ''${utils.n2l.resolve funcunsafe_mult}(1, 2)''; };
          metatest = utils.n2l.types.inline-safe.mk ''${utils.n2l.resolve with_meta_call}()'';
        };
      };
    };
  };
in utils.baseBuilder luaPath {
    inherit (inputs) nixpkgs;
    inherit system dependencyOverlays
    extra_pkg_config nixCats_passthru;
  } categoryDefinitions packageDefinitions packagename
