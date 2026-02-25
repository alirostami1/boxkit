local markdown = require("notes.markdown")
local util = require("notes.util")

local M = {}

function M.insert_link_with_fzf()
  local fzf = require("fzf-lua")
  local fzf_path = require("fzf-lua.path")
  local bufdir = util.buf_dir()

  fzf.files({
    cwd = bufdir,
    prompt = "Link file> ",
    complete = function(selected, opts, line, col)
      if not selected or not selected[1] then
        return line, col
      end

      local entry = fzf_path.entry_to_file(selected[1], opts)
      local abs = entry and entry.path or selected[1]
      local rel = util.relative_path(abs, bufdir)
      local link = markdown.link_for_path(rel)
      local newline = line:sub(1, col) .. link .. line:sub(col + 1)
      return newline, col + #link
    end,
  })
end

function M.setup_buffer_keymaps(bufnr)
  vim.keymap.set("n", "<leader>lf", M.insert_link_with_fzf, {
    buffer = bufnr,
    desc = "Pick file (fzf-lua) and insert markdown link",
  })
end

return M
