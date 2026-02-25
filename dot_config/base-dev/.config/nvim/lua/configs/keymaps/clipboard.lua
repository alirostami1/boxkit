-- paste without overwriting clipboard
vim.keymap.set("x", "<leader>p", [["_dP]])

-- yank to system clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- delete without overwriting clipboard
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])
