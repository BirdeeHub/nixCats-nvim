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

-- Test some stuff here

print(vim.inspect(nixCats('nixCats_test_names')))

-- Still deciding if I want to do it this way, use buster, or both

if nixCats('killAfter') then
    vim.schedule(function()
        vim.cmd('qa!')
    end)
end
