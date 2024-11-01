_G.my_assert = function(c, message)
    if not c then
        if nixCats('killAfter') then
            print("assertion failed: " .. message)
            vim.cmd.cquit()
        else
            error("assertion failed: " .. message)
        end
    end
end

require("libT")

if nixCats('killAfter') then
    vim.schedule(function()
        vim.cmd('qa!')
    end)
end
