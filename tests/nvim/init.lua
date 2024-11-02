make_test("hello", function()
    assert.truthy(nixCats("nixCats_test_names.hello"))
end)

-- NOTE: done this way so config still
-- gets ran when lua_dir test is not enabled
local ok, err = pcall(require, "config")
make_test("lua_dir", function()
    assert.truthy(ok, err)
end)
