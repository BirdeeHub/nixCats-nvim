make_test("pluginfile", function()
    assert.truthy(nixCats('nixCats_test_names.pluginfile'))
end)
make_test("nixos_user_hello", function()
    assert.truthy(nixCats("nixCats_test_names.nixos_user_hello"))
end)
make_test("nixos_hello", function()
    assert.truthy(nixCats("nixCats_test_names.nixos_hello"))
end)
make_test("home_hello", function()
    assert.truthy(nixCats("nixCats_test_names.home_hello"))
end)
