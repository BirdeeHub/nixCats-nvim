-- Copyright (c) 2023 BirdeeHub 
-- Licensed under the MIT license 
if nixCats('nixCats_test_lib_deps') then
    ---@type table<string, true|string>
    local states = {}
    local toRun = vim.iter(nixCats("nixCats_test_names")):map(function(k, v) return v and k or nil end):filter(function(v) return v ~= nil end):totable()
    local is_nightly = os.getenv([[IS_NIGHTLY_NVIM]])
    local nvim_version = vim.version()
    local version_str = string.format("%d.%d.%d", nvim_version.major, nvim_version.minor, nvim_version.patch)

    local function finalize(fstates)
        local colors = require('ansicolors')
        if is_nightly then
            io.stdout:write(colors("%{cyan}Running tests for nightly package: " .. nixCats.settings("nixCats_packageName") .. "%{reset}\n"))
            io.stdout:write(colors("%{cyan} nvim version: " .. version_str .. "%{reset}\n"))
        else
            io.stdout:write(colors("%{magenta}Running tests for package: " .. nixCats.settings("nixCats_packageName") .. "%{reset}\n"))
            io.stdout:write(colors("%{magenta} nvim version: " .. version_str .. "%{reset}\n"))
        end
        for k, v in pairs(fstates) do
            if v == true then
                io.stdout:write(colors("%{green}PASS:%{reset} " .. k .. "\n"))
            else
                io.stdout:write(colors("%{red}FAIL:%{reset} " .. k .. "\n"))
                local msg = (type(v) == "string" and v) or vim.inspect(v)
                io.stdout:write(msg .. "\n")
            end
        end
        local total_num = #toRun
        local passed = #vim.iter(fstates):filter(function(_, v) return v == true end):totable()
        io.stdout:write(colors((passed == total_num and '%{green}' or '%{red}') .. "Passed " .. tostring(passed) .. " out of " .. tostring(total_num) .. " tests.%{reset}\n"))
        if passed == total_num then
            if nixCats('killAfter') then
                vim.schedule(function()
                    vim.cmd('qa!')
                end)
            else
                vim.notify("testing done!")
            end
        else
            if nixCats('killAfter') then
                vim.cmd.cquit()
            else
                vim.notify("testing done!")
            end
        end
    end

    if #toRun == 0 then
        finalize(states)
    end

    local handler = {
        spec_field = "test",
        modify = function(plugin)
            if vim.tbl_contains(toRun, plugin.name) then
                plugin.enabled = true
            else
                plugin.enabled = false
            end
            plugin.load = function(name)
                local ok, err = pcall(plugin.test)
                if ok then
                    states[name] = true
                else
                    states[name] = err
                end
            end
            return plugin
        end,
        add = function(plugin)
            if plugin.test ~= nil then
                require('lze').trigger_load(plugin.name)
                local all_done = vim.iter(toRun):all(function(v)
                    return (states[v] and true) or false
                end)
                if all_done then
                    finalize(states)
                end
            end
        end,
    }
    require('lze').register_handlers(handler)

    local assert = require('luassert')
    local make_test = function(name,func)
        require('lze').load {
            name,
            test = func,
        }
    end
    _G.assert = assert
    _G.make_test = make_test
    return { make_test = make_test, assert = assert }
end
