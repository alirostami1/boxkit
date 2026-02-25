if vim.b.notes_markdown_ftplugin_loaded then
  return
end
vim.b.notes_markdown_ftplugin_loaded = true

vim.opt_local.conceallevel = 2
vim.opt.spelllang = "en_us"
vim.opt.spell = true

pcall(vim.treesitter.start)
vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.wo.foldmethod = "expr"

local bufnr = vim.api.nvim_get_current_buf()

require("notes.features.fzf_links").setup_buffer_keymaps(bufnr)
require("notes.features.new_from_visual").setup_buffer_keymaps(bufnr)

-- insert time/date
vim.keymap.set("n", "<leader>tt", function()
  vim.api.nvim_put({ vim.fn.strftime("%H:%M") }, "c", true, true)
end, { buffer = bufnr, desc = "Insert current time" })
vim.keymap.set("n", "<leader>td", function()
  vim.api.nvim_put({ vim.fn.strftime("%Y-%m-%d") }, "c", true, true)
end, { buffer = bufnr, desc = "Insert current date" })

vim.keymap.set("n", "<leader>t", function()
  require("notes.markdown").toggle_task_at_cursor()
end, {
  buffer = bufnr,
  desc = "Toggle markdown task",
})
