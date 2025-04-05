local M = {}
local attributes = {
    "cats",
    "settings",
    "pawsible",
    "petShop",
    "extra",
    "vimPackDir",
    "configDir",
    "nixCatsPath",
    "packageBinPath",
}
function M.command(opts)
    local function basic_lua_popup(input)
        local function mk_popup(text)
            local contents = {}
            for line in text:gmatch("[^\r\n]+") do
                table.insert(contents, line)
            end
            local bufnr = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
            vim.bo[bufnr].modifiable = false
            vim.bo[bufnr].readonly = true
            vim.bo[bufnr].filetype = "lua"

            -- Get maximum width of text
            local width = 0
            for _, line in ipairs(contents) do
                width = math.max(width, #line)
            end

            -- cap to screen size with margin
            local height = #contents
            local win_width = math.min(width + 2, vim.o.columns - 4)
            local win_height = math.min(height + 2, vim.o.lines - 4)
            local popopts = {
                relative = "editor",
                width = win_width,
                height = win_height,
                row = (vim.o.lines - win_height) / 2,
                col = (vim.o.columns - win_width) / 2,
                style = "minimal",
                border = "rounded",
            }

            -- make the window
            local win_id = vim.api.nvim_open_win(bufnr, true, popopts)
            vim.wo[win_id].signcolumn = "no"
            vim.wo[win_id].number = false
            vim.wo[win_id].relativenumber = false

            vim.api.nvim_buf_set_keymap(bufnr, "n", "q", "<Cmd>close<CR>", { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(bufnr, "n", "<Esc>", "<Cmd>close<CR>", { noremap = true, silent = true })

            vim.api.nvim_create_autocmd("BufLeave", {
                buffer = bufnr,
                once = true,
                callback = function()
                    vim.api.nvim_win_close(win_id, true)
                end,
            })
        end
        local ok, msg = pcall(mk_popup, input)
        if not ok then
            print("Popup failed to open due to error: " .. msg)
            print("Falling back to print()")
            print(input)
        end
    end

    local display = vim.g.nixcats_debug_ui ~= false and basic_lua_popup or print

    if #opts.fargs == 0 then
        display(vim.inspect(nixCats.cats))
        return
    elseif #opts.fargs == 1 then
        if vim.list_contains(attributes, opts.fargs[1]) then
            display(vim.inspect(nixCats[opts.fargs[1]]))
            return
        end
    elseif #opts.fargs == 2 then
        if opts.fargs[1] == 'cat' or opts.fargs[1] == 'get' then
            display(vim.inspect(nixCats.get(opts.fargs[2])))
            return
        end
    elseif #opts.fargs > 2 then
        local first = table.remove(opts.fargs, 1)
        if first == 'cat' or first == 'get' then
            display(vim.inspect(nixCats.get(opts.fargs)))
            return
        end
    end
end

function M.complete(ArgLead, CmdLine, CursorPos)
    local argsTyped = {}
    local cmdLineBeforeCursor = CmdLine:sub(1, CursorPos)
    for v in cmdLineBeforeCursor:gmatch("([^%s]+)") do
        table.insert(argsTyped, v)
    end
    local numSpaces = 0
    for _ in cmdLineBeforeCursor:gmatch("([%s]+)") do
        numSpaces = numSpaces + 1
    end
    local candidates = vim.list_extend({ "cat", "get" }, attributes)
    local matches = {}

    if not (#argsTyped > 1) then
        for _, candidate in ipairs(candidates) do
            if candidate:sub(1, #ArgLead) == ArgLead then
                table.insert(matches, candidate)
            end
        end
    elseif argsTyped[2] == 'cat' or argsTyped[2] == 'get' then
        table.remove(argsTyped, 1)
        table.remove(argsTyped, 1)
        local argsSoFar = {}
        -- Split on dots or whitespace
        if #argsTyped == 1 then
            for key in argsTyped[1]:gmatch("([^%.]+)") do
                table.insert(argsSoFar, key)
            end
        elseif #argsTyped > 1 then
            argsSoFar = argsTyped
        else
            return matches
        end
        -- Walk table till end of argsSoFar,
        -- and offer matching completion options
        ---@type any
        local cats = nixCats.cats
        for index, key in pairs(argsSoFar) do
            if index == #argsSoFar then
                for name, value in pairs(cats) do
                    if type(value) == "table" and name == key then
                        for k, _ in pairs(value) do
                            table.insert(matches, k)
                        end
                        -- name ~= key and numSpaces - 2 < #argsSoFar
                        -- this is for preventing options from previous level from completing after hitting space
                        -- CmdLine:sub(CursorPos, CursorPos) ~= '.' is for the same reason but for the dot syntax
                    elseif name:sub(1, #key) == key and numSpaces - 2 < #argsSoFar and CmdLine:sub(CursorPos, CursorPos) ~= '.' then
                        table.insert(matches, name)
                    end
                end
            else
                cats = cats[key]
                if type(cats) ~= "table" then
                    break
                end
            end
        end
    end

    return matches

end
return M
