local M = {}

---This function is useful for sourcing the after directories of lazily loaded plugins
---because vim.cmd.packadd does not do this for you.
---
---This might be useful when doing lazy loading the vanilla way
---as well as when using plugins like lz.n for lazy loading
---It is primarily useful for lazily loading nvim-cmp sources,
---as they often rely on the after directory to work
---
---Recieves the names of directories from a plugin's after directory
---that you wish to source files from.
---Will return a load function that can take a name, or list of names,
---and will load a plugin and its after directories.
---The function returned is a suitable substitute for the load field of a plugin spec.
---
---Only makes sense for plugins added via optionalPlugins
---or some other opt directory on your packpath
---
---e.g. in the following example:
---load_with_after_plugin will load the plugin names it is given, and their after/plugin dir
---
---local load_with_after_plugin = require('nixCatsUtils').make_load_with_after({ 'plugin' })
---load_with_after_plugin('some_plugin')
---@overload fun(dirs: string[]|string): fun(names: string|string[])
---It also optionally recieves a function that should load a plugin and return its path
---for if the plugin is not on the packpath, or return nil
---to load from the packpath or nixCats list as normal
---@overload fun(dirs: string[]|string, load: fun(name: string):string|nil): fun(names: string|string[])
function M.make_load_with_after(dirs, load)
    dirs = (type(dirs) == "table" and dirs) or { dirs }
    local fromPackpath = function(name)
        for _, packpath in ipairs(vim.opt.packpath:get()) do
            local plugin_path = vim.fn.globpath(packpath, "pack/*/opt/" .. name, nil, true, true)
            if plugin_path[1] then
                return plugin_path[1]
            end
        end
        return nil
    end
    ---@param plugin_names string[]|string
    return function(plugin_names)
        local names
        if type(plugin_names) == "table" then
            names = plugin_names
        elseif type(plugin_names) == "string" then
            names = { plugin_names }
        else
            return
        end
        local to_source = {}
        for _, name in ipairs(names) do
            if type(name) == "string" then
                local path = (type(load) == "function" and load(name)) or nil
                if type(path) == "string" then
                    table.insert(to_source, { name = name, path = path })
                else
                    ---@diagnostic disable-next-line: param-type-mismatch
                    local ok, err = pcall(vim.cmd, "packadd " .. name)
                    if ok then
                        table.insert(to_source, { name = name, path = nil })
                    else
                        vim.notify(
                            '"packadd '
                                .. name
                                .. '" failed, and path provided by custom load function (if provided) was not a string\n'
                                .. err,
                            vim.log.levels.WARN,
                            { title = "nixCatsUtils.load_with_after" }
                        )
                    end
                end
            else
                vim.notify(
                    "plugin name was not a string and was instead of value:\n" .. vim.inspect(name),
                    vim.log.levels.WARN,
                    { title = "nixCatsUtils.load_with_after" }
                )
            end
        end
        for _, info in pairs(to_source) do
            local plugpath = info.path or vim.tbl_get(package.loaded, "nixCats", "pawsible", "allPlugins", "opt", info.name) or fromPackpath(info.name)
            if type(plugpath) == "string" then
                local afterpath = plugpath .. "/after"
                for _, dir in ipairs(dirs) do
                    if vim.fn.isdirectory(afterpath) == 1 then
                        local plugin_dir = afterpath .. "/" .. dir
                        if vim.fn.isdirectory(plugin_dir) == 1 then
                            local files = vim.fn.glob(plugin_dir .. "/*", false, true)
                            for _, file in ipairs(files) do
                                if vim.fn.filereadable(file) == 1 then
                                    vim.cmd("source " .. file)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- A nixCats specific lze handler that you can use to conditionally enable by category easier.
-- at the start of your config, register with
-- require('lze').register_handlers(require('nixCatsUtils.lzUtils').for_cat)
-- before any calls to require('lze').load using the handler have been made.
-- accepts:
-- for_cat = { "your" "cat" }; for_cat = { cat = { "your" "cat" }, default = bool }
-- for_cat = "your.cat"; for_cat = { cat = "your.cat", default = bool }
-- where default is an alternate value for when nixCats was NOT used to install the config
M.for_cat = {
    spec_field = "for_cat",
    set_lazy = false,
    modify = function(plugin)
        if type(plugin.for_cat) == "table" then
            if plugin.for_cat.cat ~= nil then
                if vim.g[ [[nixCats-special-rtp-entry-nixCats]] ] ~= nil then
                    plugin.enabled = (nixCats(plugin.for_cat.cat) and true) or false
                else
                    plugin.enabled = nixCats(plugin.for_cat.default)
                end
            else
                plugin.enabled = (nixCats(plugin.for_cat) and true) or false
            end
        else
            plugin.enabled = (nixCats(plugin.for_cat) and true) or false
        end
        return plugin
    end,
}

return M
