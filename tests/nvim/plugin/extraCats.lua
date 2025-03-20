make_test("extraCats", function()
    if nixCats("fi") and nixCats("foe") and nixCats("cowboy") then
        assert.truthy(nixCats('foo.default'))
    else
        assert.falsy(nixCats('foo.default'))
    end
    if nixCats("cowboy") then
        assert.truthy(nixCats('bee.bop'))
    end
    assert.truthy(nixCats("cond_works_for_sub_cats"))
end)
make_test("whencat", function()
    assert.truthy(nixCats('whencat'))
    assert.falsy(nixCats('whencat_this_shouldnt_be_included'))
    assert.truthy(nixCats('whencat_is_enabled'))
end)
