if vim.b.notes_typst_ftplugin_loaded then
  return
end
vim.b.notes_typst_ftplugin_loaded = true

local bufnr = vim.api.nvim_get_current_buf()

vim.opt_local.spelllang = "en_us"
vim.opt_local.spell = true
vim.opt_local.wrap = true
vim.opt_local.linebreak = true

pcall(vim.treesitter.start)
vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.wo.foldmethod = "expr"

-- insert time/date
vim.keymap.set("n", "<leader>tt", function()
  vim.api.nvim_put({ vim.fn.strftime("%H:%M") }, "c", true, true)
end, { buffer = bufnr, desc = "Insert current time" })

vim.keymap.set("n", "<leader>td", function()
  vim.api.nvim_put({ vim.fn.strftime("%Y-%m-%d") }, "c", true, true)
end, { buffer = bufnr, desc = "Insert current date" })
