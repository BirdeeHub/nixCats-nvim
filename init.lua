
-- when wrapRc setting is true, this file will not execute.
-- it will instead do the wrapped equivalent of this.
-- when wrapRc setting is false, this file will be executed.
-- Leave it unchanged, so that you dont have a different config
-- between unwrapped and wrapped lua configurations.

require(require('nixCats').RCName)
-- when using wrapRc = false, if you don't set RCName
-- this obviously won't find the right thing to require
-- so either set RCName in the flake, or make this require your folder of choice
