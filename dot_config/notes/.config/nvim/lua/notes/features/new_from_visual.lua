local markdown = require("notes.markdown")
local util = require("notes.util")

local M = {}

local uv = vim.uv or vim.loop

local function get_visual_selection()
  local bufnr = 0
  local srow, scol = unpack(vim.api.nvim_buf_get_mark(bufnr, "<"))
  local erow, ecol = unpack(vim.api.nvim_buf_get_mark(bufnr, ">"))

  if srow == 0 or erow == 0 then
    return nil
  end

  if (srow > erow) or (srow == erow and scol > ecol) then
    srow, erow = erow, srow
    scol, ecol = ecol, scol
  end

  local lines = vim.api.nvim_buf_get_text(bufnr, srow - 1, scol, erow - 1, ecol + 1, {})
  local text = table.concat(lines, "\n")
  return text, srow, scol, erow, ecol
end

local function write_file_if_missing(path, title)
  if uv.fs_stat(path) then
    return false
  end

  local fd = assert(uv.fs_open(path, "w", 420))
  local content = ("# %s\n\n"):format(title)
  assert(uv.fs_write(fd, content, 0))
  assert(uv.fs_close(fd))
  return true
end

function M.create_note_from_visual()
  local text, srow, scol, erow, ecol = get_visual_selection()
  if not text then
    return
  end

  local raw = util.collapse_ws(text)
  if raw == "" then
    return
  end

  local title = util.title_case_words(raw)
  local filename = util.slugify_markdown_filename(raw)

  local bufdir = util.buf_dir()
  local root = util.project_root(bufdir)

  local abs = util.normalize(root .. "/" .. filename)
  local rel = util.relative_path(abs, bufdir)

  write_file_if_missing(abs, title)

  local link = markdown.link_for_path(rel, {
    text = title,
    wrap_spaces = false,
  })

  vim.api.nvim_buf_set_text(0, srow - 1, scol, erow - 1, ecol + 1, { link })
end

function M.setup_user_command()
  local commands = vim.api.nvim_get_commands({ builtin = false })
  if commands.MdNewFromVisual then
    return
  end

  vim.api.nvim_create_user_command("MdNewFromVisual", function()
    M.create_note_from_visual()
  end, { range = true })
end

function M.setup_buffer_keymaps(bufnr)
  vim.keymap.set("x", "<leader>mn", function()
    M.create_note_from_visual()
  end, {
    buffer = bufnr,
    desc = "Create note from selection (project root) + insert link",
    silent = true,
  })
end

return M
