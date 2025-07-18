{ nclib
, nixCats_packageName
, settings
, final_cat_defs_set
, plugins
, invalidHostNames
, combineCatsOfFuncs
, filterAndFlattenEnvVars
, filterAndFlattenWrapArgs
, filterAndFlattenXtraWrapArgs
# from callPackage
, pkgs
, lib
, python3
, perl
, ruby
, nodejs
, nodePackages
, bundlerEnv
, ...
}: let

  defaults = {
    python3 = {
      path = depfn: {
        value = (python3.withPackages (p: depfn p ++ [p.pynvim])).interpreter;
        args = [ "--unset" "PYTHONPATH" ];
      };
      pluginAttr = "python3Dependencies";
    };
    node = {
      path = {
        value = "${pkgs.neovim-node-client or nodePackages.neovim}/bin/neovim-node-host";
        nvimArgs = [ "--suffix" "PATH" ":" "${nodejs}/bin" ];
      };
    };
    perl = {
      path = depfn: "${perl.withPackages (p: depfn p ++ [ p.NeovimExt p.Appcpanminus ])}/bin/perl";
    };
    ruby = {
      path = let
        rubyEnv = bundlerEnv {
          name = "neovim-ruby-env";
          postBuild = "ln -sf ${ruby}/bin/* $out/bin";
          gemdir = "${pkgs.path}/pkgs/applications/editors/neovim/ruby_provider";
        };
      in {
        value = "${rubyEnv}/bin/neovim-ruby-host";
        nvimArgs = [ "--set" "GEM_HOME" "${rubyEnv}/${rubyEnv.ruby.gemPath}" "--suffix" "PATH" ":" "${rubyEnv}/bin" ];
      };
    };
  };

  mkHost = with builtins; name: host_set:
    assert (elem name invalidHostNames) -> throw ''
      nixCats: hosts must not share a name with an already existing categoryDefinitions section
    '';
  let
    host_settings = (defaults.${name} or {}) // host_set;
    get_dependencies = x: attrname: concatLists (map (v:
      if x == null && lib.isFunction (v.${attrname} or null) then (import ./errors.nix).hostDeps name attrname
      else if lib.isFunction (v.${attrname} or null) then v.${attrname} x else v.${attrname} or []
    ) plugins);
    libraryFunc = x: let
      OGfn = combineCatsOfFuncs name (final_cat_defs_set.${name}.libraries or {});
    in OGfn x ++ lib.optionals (isString (host_settings.pluginAttr or null)) (get_dependencies x host_settings.pluginAttr);
    pathRes = if lib.isFunction host_settings.path
      then host_settings.path libraryFunc
      else host_settings.path or ((import ./errors.nix).hostPath name);
    extraWrapperArgs = filterAndFlattenXtraWrapArgs name (final_cat_defs_set.${name}.extraWrapperArgs or {});
    wrapperArgsPre = filterAndFlattenWrapArgs name (final_cat_defs_set.${name}.wrapperArgs or {});
    envArgs = filterAndFlattenEnvVars name (final_cat_defs_set.${name}.envVars or {});
    wrapperArgs = wrapperArgsPre ++ (pathRes.args or []) ++ envArgs;
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
    cmd = if extraWrapperArgs == [] && wrapperArgs == []
      then "ln -s ${lib.escapeShellArgs [ (pathRes.value or pathRes) "${placeholder "out"}/bin/${nixCats_packageName}-${name}" ]}"
      else "makeWrapper ${lib.escapeShellArgs [ (pathRes.value or pathRes) "${placeholder "out"}/bin/${nixCats_packageName}-${name}" ]} ${wrapperArgsStr}";
    enable = host_settings.enable or false;
    nvim_host_args = pathRes.nvimArgs or [];
    nvim_host_var = "vim.g[ ${nclib.n2l.uglyLua globalname} ]";
    disabled = lib.optional (host_settings.enable or null == false && isString disabledname)
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
    nvim_host_vars = acc.nvim_host_vars ++ [ "${host.nvim_host_var}=${nclib.n2l.uglyLua "${placeholder "out"}/bin/${nixCats_packageName}-${host.name}"}" ];
  } else {
    nvim_host_vars = acc.nvim_host_vars ++ host.disabled;
  });

in with builtins;
lib.pipe (settings.hosts or {}) [
  (lib.mapAttrsToList mkHost)
  (foldl' combineHosts {
    host_phase = "";
    nvim_host_args = [];
    nvim_host_vars = [];
    final_settings = settings;
  })
  (v: v // {
    new_sections = lib.pipe (lib.recursiveUpdate defaults (settings.hosts or {})) [
      (mapAttrs (n: v: if nclib.ncIsAttrs v && v ? path then lib.isFunction v.path else null))
      (lib.filterAttrs (n: v: v != null))
      (mapAttrs (n: v: ["envVars" "wrapperArgs" "extraWrapperArgs"] ++ lib.optional v "libraries"))
      (lib.mapAttrsToList (n: value: map (v: [ n v ]) value))
      concatLists
    ];
  })
]
