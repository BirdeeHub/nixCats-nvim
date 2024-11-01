if nixCats('nixCats_test_lib_deps') then
    ---@type table<string, true|string>
    local states = {}
    local toRun = vim.iter(nixCats("nixCats_test_names")):map(function(k, v) return (v and k) or nil end):filter(function(v) return v ~= nil end):totable()
    require('luassert')

    local function finalize(fstates)
        for k, v in pairs(fstates) do
            if v == true then
                print("PASS: " .. k)
            else
                local msg = (type(v) == "string" and v) or vim.inspect(v)
                print("FAIL: " .. k .. "\n" .. msg)
            end
        end
        local total_num = #toRun
        local passed = #vim.tbl_keys(vim.iter(fstates):filter(function(_, v) return v == true end):totable())
        print("passed " .. tostring(passed) .. " out of " .. tostring(total_num) .. " tests.")
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

    _G.make_test = function(name,func)
        require('lze').load {
            name,
            test = func,
        }
    end
end
