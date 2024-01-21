importName: inputs: let
  overlay = self: super: { 
    ${importName} = {

      lazy-nvim = super.vimUtils.buildVimPlugin {
        pname = "lazy.nvim";
        version = "2024-01-21";
        src = super.fetchFromGitHub {
          owner = "folke";
          repo = "lazy.nvim";
          rev = "28126922c9b54e35a192ac415788f202c3944c9f";
          sha256 = "sha256-Qicyec1ZvSb5JVVTW8CrTjndHCLso8Rb2V5IA6D4Rps=";
        };
        meta.homepage = "https://github.com/folke/lazy.nvim/";
      };

      # I needed to do this because the one on nixpkgs wasnt working
      # reddit user bin-c found this link for me.
      # and I adapted the funtion to my overlay
      # It is the entry from nixpkgs.
      # https://github.com/NixOS/nixpkgs/blob/44a691ec0cdcd229bffdea17455c833f409d274a/pkgs/applications/editors/vim/plugins/overrides.nix#L746
      markdown-preview-nvim =  let
        nodeDep = super.yarn2nix-moretea.mkYarnModules rec {
          inherit (super.vimPlugins.markdown-preview-nvim) pname version;
          packageJSON = "${super.vimPlugins.markdown-preview-nvim.src}/package.json";
          yarnLock = "${super.vimPlugins.markdown-preview-nvim.src}/yarn.lock";
          offlineCache = super.fetchYarnDeps {
            inherit yarnLock;
            hash = "sha256-kzc9jm6d9PJ07yiWfIOwqxOTAAydTpaLXVK6sEWM8gg=";
          };
        };
      in super.vimPlugins.markdown-preview-nvim.overrideAttrs {
        # apparently I dont need this?
        # patches = [
        #   (super.substituteAll {
        #     src = "${super.vimPlugins.markdown-preview-nvim.src}/fix-node-paths.patch";
        #     node = "${super.nodejs}/bin/node";
        #   })
        # ];
        postInstall = ''
          ln -s ${nodeDep}/node_modules $out/app
        '';

        nativeBuildInputs = [ super.nodejs ];
        doInstallCheck = true;
        installCheckPhase = ''
          node $out/app/index.js --version
        '';
      };


    };
  };
in
overlay
