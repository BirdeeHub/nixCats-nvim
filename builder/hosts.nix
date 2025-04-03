{ nclib
, nixCats_packageName
, initial_settings # <- post removal of deprecations, this should be renamed to settings
, final_cat_defs_set
, plugins
, invalidHostNames
, combineCatsOfFuncs
, filterAndFlattenEnvVars
, filterAndFlattenWrapArgs
, filterFlattenUnique
# from callPackage
, pkgs
, lib
, python3
, perl
, ruby
, nodePackages
, bundlerEnv
, ...
}: let

  # post removal of deprecations, this should be removed
  settings = with builtins; let
    deprecated = {
      withNodeJs = "node";
      withPython3 = "python3";
      withRuby = "ruby";
      withPerl = "perl";
    };
    deprecate = old: name: value: nclib.warnfn ''
      nixCats setting ${old} is deprecated in favor of "hosts.${name}.enable"
      see: [:help nixCats.flake.outputs.settings.hosts](https://nixcats.org/nixCats_format.html#nixCats.flake.outputs.settings.hosts)
    '' value;
  in initial_settings // (foldl' (acc: n:
      acc // (lib.optionalAttrs (isString (deprecated.${n} or null)) {
        hosts = acc.hosts // { ${deprecated.${n}}.enable = deprecate n deprecated.${n} initial_settings.${n}; };
      })
    ) { hosts = initial_settings.hosts; } (attrNames initial_settings));

  # the post deprecation version is in the help for hosts
  # :h nixCats.flake.outputs.settings.hosts
  defaults = {
    python3 = {
      path = depfn: {
        value = (python3.withPackages (p: depfn p ++ [p.pynvim])).interpreter;
        args = let
          res = lib.optionals (settings.disablePythonPath or true) [ "--unset" "PYTHONPATH" ]
          ++ lib.optionals (settings.disablePythonSafePath or false) [ "--unset" "PYTHONSAFEPATH" ];
          in if settings ? disablePythonPath || settings ? disablePythonSafePath then nclib.warnfn (lib.optionalString (!(settings.disablePythonPath or true)) ''
            nixCats: settings.disablePythonPath is deprecated.
            to override the default value of true, (removing it)
            redefine the python3 host path to:
            hosts.python3.path = depfn: (python3.withPackages (p: depfn p ++ [p.pynvim]));
            in order to prevent it from providing
            [ "--unset" "PYTHONPATH" ] wrapper arguments by default
          '' + lib.optionalString (settings.disablePythonSafePath or false) ''
            nixCats: settings.disablePythonSafePath is deprecated.
            in categoryDefinitions, define the following instead
            python3.wrapperArgs = {
              yourcatname = [
                [ "--unset" "PYTHONSAFEPATH" ]
              ];
            }
          '') res else res;
      };
      pluginAttr = "python3Dependencies";
    };
    node = {
      path = {
        value = "${pkgs.neovim-node-client or nodePackages.neovim}/bin/neovim-node-host";
        nvimArgs = [ "--suffix" "PATH" ":" "${pkgs.nodejs}/bin" ];
      };
    };
    perl = {
      path = depfn: "${perl.withPackages (p: depfn p ++ [ p.NeovimExt p.Appcpanminus ])}/bin/perl";
    };
    ruby = {
      path = let
        gemPath = if settings ? "gem_path" then nclib.warnfn ''
          nixCats: settings.gem_path deprecated.
          Redefine ruby host path value instead.

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
          '' settings.gem_path
           else "${pkgs.path}/pkgs/applications/editors/neovim/ruby_provider";
        rubyEnv = bundlerEnv {
          name = "neovim-ruby-env";
          postBuild = "ln -sf ${ruby}/bin/* $out/bin";
          gemdir = gemPath;
        };
      in {
        value = "${rubyEnv}/bin/neovim-ruby-host";
        nvimArgs = [ "--set" "GEM_HOME" "${rubyEnv}/${rubyEnv.ruby.gemPath}" "--suffix" "PATH" ":" "${rubyEnv}/bin" ];
      };
    };
  };

  get_dependencies = attrname: lib.pipe plugins [
    (map (v: v.${attrname} or []))
    builtins.concatLists
  ];

  mkHost = with builtins; name: host_set:
    assert (elem name invalidHostNames) -> throw ''
      nixCats: hosts must not share a name with an already existing categoryDefinitions section
    '';
  let
    host_settings = (defaults.${name} or {}) // host_set;
    libraryFunc = x: let
      OGfn = combineCatsOfFuncs name (final_cat_defs_set.${name}.libraries or {});
    in OGfn x ++ lib.optionals (isString (host_settings.pluginAttr or null)) (get_dependencies host_settings.pluginAttr);
    pathRes = if lib.isFunction host_settings.path
      then host_settings.path libraryFunc
      else host_settings.path or ((import ./errors.nix).hostPath name);
    path = pathRes.value or pathRes;
    extraWrapperArgs = filterFlattenUnique (final_cat_defs_set.${name}.extraWrapperArgs or {});
    wrapperArgsPre = filterAndFlattenWrapArgs name (final_cat_defs_set.${name}.wrapperArgs or {});
    envArgs = filterAndFlattenEnvVars name (final_cat_defs_set.${name}.envVars or {});
    wrapperArgs = wrapperArgsPre ++ (pathRes.args or []) ++ envArgs;
    towrap = extraWrapperArgs != [] && wrapperArgs != [];
    wrapperArgsStr = concatStringsSep " " ([ (lib.escapeShellArgs wrapperArgs) ] ++ extraWrapperArgs);
    globalname = host_settings.global or "${name}_host_prog";
    disabledname = host_settings.disabled or "loaded_${name}_provider";
  in
    assert (isString (host_settings.global or "")) || (import ./errors.nix).hosts name "global" "string";
    assert (isBool (host_settings.enable or true)) || (import ./errors.nix).hosts name "enable" "boolean";
    assert (isString (host_settings.pluginAttr or "") || (host_settings.pluginAttr or null) == null) || (import ./errors.nix).hosts name "pluginAttr" "string or null";
    assert (isString (host_settings.disabled or "") || (host_settings.disabled or null) == null) || (import ./errors.nix).hosts name "disabled" "string or null";
  {
    inherit name;
    cmd = if towrap then "makeWrapper ${path} ${placeholder "out"}/bin/${nixCats_packageName}-${name} ${wrapperArgsStr}"
      else "ln -s ${path} ${placeholder "out"}/bin/${nixCats_packageName}-${name}";
    enable = host_settings.enable or false;
    nvim_host_args = pathRes.nvimArgs or [];
    nvim_host_var = "vim.g[ ${nclib.n2l.uglyLua globalname} ]";
    disabled = lib.optional (host_settings.enable or null == false && isString (host_settings.disabled or null))
      "vim.g[ ${nclib.n2l.uglyLua disabledname} ]=0";
    host_settings = removeAttrs host_settings ["path"] // {
      global = globalname;
      disabled = disabledname;
    } // (lib.optionalAttrs (host_settings.enable or false) {
      path = nclib.n2l.types.inline-unsafe.mk { body = "vim.g[ ${nclib.n2l.uglyLua globalname} ]"; };
    });
  };

  combineHosts = acc: host: acc // {
    final_settings = acc.final_settings // {
      hosts = (acc.final_settings.hosts or {}) // {
        ${host.name} = builtins.removeAttrs (acc.final_settings.hosts.${host.name} or {}) ["path"] // host.host_settings;
      };
    };
  } // (if host.enable then {
    # string with makeWrapper calls or ln -s for buildPhase
    host_phase = acc.host_phase + "\n" + host.cmd;
    # wrapper args for nvim from hosts
    nvim_host_args = acc.nvim_host_args ++ host.nvim_host_args;
    # generateProviderRc
    nvim_host_vars = acc.nvim_host_vars ++ [ "${host.nvim_host_var}=[[${placeholder "out"}/bin/${nixCats_packageName}-${host.name}]]" ];
  } else {
    nvim_host_vars = acc.nvim_host_vars ++ host.disabled;
  });

in with builtins;
lib.pipe (settings.hosts or {}) [
  (mapAttrs mkHost)
  attrValues
  (foldl' combineHosts {
    host_phase = "";
    nvim_host_args = [];
    nvim_host_vars = [];
    final_settings = settings;
  })
]
