make_test("remote-host", function()
    assert.truthy(vim.fn.filereadable(vim.g.node_host_prog) == 1)
    assert.truthy(vim.fn.filereadable(vim.g.python3_host_prog) == 1)
end)
