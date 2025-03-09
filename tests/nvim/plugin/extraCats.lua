make_test("extraCats", function()
    if nixCats("fi") and nixCats("foe") and nixCats("cowboy") then
        assert.truthy(nixCats('foo.default'))
    else
        assert.falsy(nixCats('foo.default'))
    end
    if nixCats("cowboy") then
        assert.truthy(nixCats('bee.bop'))
    end
end)
