---@meta
error("Cannot import a meta module")

---@class nixCats
---@field cats table
---@field pawsible table
---@field settings table
---@field petShop table
---@field nixCatsPath string
---@field vimPackDir string
---@field configDir string
---@field packageBinPath string
---internal: this creates the nixCats global commands
---@field addGlobals fun() 
---internal: use the global alias, nixCats('path.to.value')
---for full compatibility with luaUtils template
---@field get fun(category: string|string[]): any --
