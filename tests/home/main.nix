{ config, pkgs, testvim, lib, username, inputs, ...  }@args: let
  mkHMdir = username: let
    homeDirPrefix = if pkgs.stdenv.hostPlatform.isDarwin then "Users" else "home";
    homeDirectory = "/${homeDirPrefix}/${username}";
  in homeDirectory;
in {
  imports = [
  ];
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = username;
  home.homeDirectory = lib.mkDefault (mkHMdir username);
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  home.stateVersion = "24.05";
  xdg.enable = true;
  nix.package = pkgs.nix;
  home.shellAliases = {
  };
  home.sessionVariables = {
    EDITOR = "nvim";
  };
  home.packages = with pkgs; [
  ];
  home.file = {
  };

  testvim = {
    enable = true;
    packageNames = [ "testvim" ];
  };
}
