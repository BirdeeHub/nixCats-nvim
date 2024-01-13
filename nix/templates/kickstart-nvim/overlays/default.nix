# The following is the overlays/default.nix file.
# you may copy paste it into a file then include it in your flake.nix
# to add new overlays you should follow 
# the directions inside the comment blocks.
# it is done this way for convenience but you could do it another way.

# When importing these overlays from one nixCats into another using its otherOverlays,
# you should use the utils.mergeOverlays function to combine them.
# This will allow you not to worry about other nixCats overlay
# imports from having import naming conflicts with your own.

/*
This file imports overlays defined in the following format.
Plugins will still only be downloaded if included in a category.
You may copy paste this example into a new file and then import that file here.
*/
# Example overlay:
/*
importName: inputs: let
  overlay = self: super: { 
    ${importName} = {
      # define your overlay derivations here
    };
  };
in
overlay
*/
inputs: let 
  overlaySet = {

    # this is how you would add another overlay file
    # for if your customBuildsOverlay gets too long
    # the name here will be the name used when importing items from it in your flake.
    # i.e. these items will be accessed as pkgs.nixCatsBuilds.thenameofthepackage
    # nixCatsBuilds = import ./customBuildsOverlay.nix;

  };
in
builtins.attrValues (builtins.mapAttrs (name: value: (value name inputs)) overlaySet)
