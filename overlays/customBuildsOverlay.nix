importName: inputs: let
  overlay = self: super: { 
    ${importName} = {

      lazy-nvim = super.vimUtils.buildVimPlugin {
        pname = "lazy.nvim";
        version = "2024-01-23";
        src = super.fetchFromGitHub {
          owner = "folke";
          repo = "lazy.nvim";
          rev = "aedcd79811d491b60d0a6577a9c1701063c2a609";
          sha256 = "sha256-8gbwjDkpXOSiLwv7fIBSZWFPi8kd6jyLMFa3S5BZXdM=";
        };
        meta.homepage = "https://github.com/folke/lazy.nvim/";
      };

    };
  };
in
overlay
