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

    };
  };
in
overlay
