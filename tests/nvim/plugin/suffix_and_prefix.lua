make_test("test_suffix_and_prefix", function()
    -- TODO: test that the lspsAndRuntimeDeps actually are suffixed or prefixed correctly
    -- either via default setting, or granular.
    -- sharedLibraries section shares the same function as well to do this so testing one should test both.

    assert.truthy(vim.fn.executable("my_test_program") == 1, "my_test_program not found on the path")
    assert.truthy(vim.fn.executable("rg") == 1, "ripgrep not found on the path")
    assert.truthy(vim.fn.executable("fd") == 1, "fd not found on the path")

    local exit_code = io.popen'my_test_program \necho _$?':read'*a':match'.*%D(%d+)'+0
    assert.equal(0, exit_code, "Program failed, wrong program first in path")
end)
