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
    startupPlugins = {
      autoconf = [
        ((pkgs.runCommandNoCC "autoconftest" {} ''mkdir -p $out'').overrideAttrs (prev: {
          passthru = prev.passthru or {} // {
            initLua = ''
              vim.g.autoconf_test_nixCats = true
            '';
          };
        }))
      ];
      autodeps = [
        ((pkgs.runCommandNoCC "autodepstest" {} ''mkdir -p $out'').overrideAttrs (prev: {
          runtimeDeps = prev.runtimeDeps or [] ++ [
            (pkgs.writeShellScriptBin "autodeps_test_nixCats" ''
              echo "HELLO WORLD I HAVE BEEN AUTOINCLUDED"
            '')
          ];
        }))
      ];
    };
    environmentVariables = {
      testvars = {
        TEST = "test";
        TEST2 = pkgs.bash;
      };
    };
    extraCats = {
      foo = [
        [ "foo" "default" ]
      ];
      cowboy = [
        [ "bee" "bop" ]
        {
          cat = [ "foo" "bar" ];
          cond = [
            [ "fi" "fie" ]
            [ "foe" "fum" ]
            [ "fi" "te" "me" ]
          ];
        }
      ];
      whencat = [
        {
          cat = [ "whencat_is_enabled" ];
          when = [
            [ "when_top_cat" "is" "enabled" ] # <- (when_top_cat = true)
          ];
        }
        {
          cat = [ "whencat_this_shouldnt_be_included" ];
          when = [
            [ "plz" ] # <- (plz.enable.deepest.subcat = true)
          ];
        }
        {
          cat = [ "cond_works_for_sub_cats" ];
          cond = [
            [ "plz" ]
          ];
        }
      ];
    };
  };
  packageDefinitions = {
    ${packagename} = { pkgs, ... }: {
      settings = {
        withNodeJs = true;
        withPython3 = true;
      };
      categories = {
        testvars = true;
        autoconf = true;
        autodeps = true;
        plz.enable.deepest.subcat = true;
        when_top_cat = true;
        whencat = true;
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
