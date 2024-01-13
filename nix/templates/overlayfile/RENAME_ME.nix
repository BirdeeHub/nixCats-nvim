# init this template into the overlays directory,
# rename it, then import it as directed it within overlays/default.nix
importName: inputs: let
  overlay = self: super: { 
    ${importName} = {
      # define your overlay derivations here
    };
  };
in
overlay
