local markdown = require("notes.markdown")
local util = require("notes.util")

local M = {}

local function in_md_url_context(line, col0)
  local before = line:sub(1, col0)
  return before:match("%]%([^)]*$") ~= nil
end

local function after_at_trigger(line, col0)
  local before = line:sub(1, col0)
  return before:match("@[%w%-%_]*$") ~= nil
end

local function replace_range(line, row1, col0, mode)
  local before = line:sub(1, col0)

  local s
  if mode == "at" then
    s = before:find("@[%w%-%_]*$")
  else
    s = before:find("[%w%-%_%.%/]*$")
  end

  if not s then
    s = col0 + 1
  end

  return {
    start = { line = row1 - 1, character = s - 1 },
    ["end"] = { line = row1 - 1, character = col0 },
  }
end

local function get_kind_text()
  local ok, types = pcall(require, "blink.cmp.types")
  if ok and types and types.CompletionItemKind and types.CompletionItemKind.Text then
    return types.CompletionItemKind.Text
  end
  return 1
end

local KIND_TEXT = get_kind_text()

function M.new(opts)
  opts = opts or {}
  local self = setmetatable({}, { __index = M })
  self.opts = opts
  self._cache = { when = 0, files = {} }
  return self
end

function M:enabled()
  return vim.bo.filetype == "markdown"
end

function M:get_trigger_characters()
  return { "@" }
end

function M:_scan_files(cb)
  local roots = self.opts.roots or { util.buf_dir() }
  local glob = self.opts.glob or "*.md"
  local files = {}
  local pending = 0

  local function add_from_root(root, list)
    root = util.normalize(root)
    for _, path in ipairs(list) do
      path = util.normalize(path)
      local abs = path:match("^/") and path or (root .. "/" .. path)
      files[#files + 1] = abs
    end
  end

  local function done()
    pending = pending - 1
    if pending == 0 then
      cb(files)
    end
  end

  local use_rg = (vim.fn.executable("rg") == 1) and (vim.system ~= nil)
  if use_rg then
    for _, root in ipairs(roots) do
      pending = pending + 1
      vim.system(
        { "rg", "--files", "--glob", glob },
        { cwd = root, text = true },
        vim.schedule_wrap(function(res)
          local list = {}
          if res.code == 0 and res.stdout then
            for line in res.stdout:gmatch("[^\r\n]+") do
              list[#list + 1] = line
            end
          end
          add_from_root(root, list)
          done()
        end)
      )
    end
    return
  end

  for _, root in ipairs(roots) do
    local found = {}
    if vim.fs and vim.fs.find then
      found = vim.fs.find(function(name)
        return name:match("%.md$")
      end, { path = root, type = "file", limit = math.huge })
    end
    add_from_root(root, found)
  end
  cb(files)
end

function M:get_completions(_, callback)
  if vim.in_fast_event() then
    vim.schedule(function()
      self:get_completions(nil, callback)
    end)
    return function() end
  end

  local row1, col0 = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()

  local want_url = in_md_url_context(line, col0)
  local want_at = after_at_trigger(line, col0)
  if not want_at and not want_url then
    callback({ items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
    return function() end
  end

  local mode = want_url and "url" or "at"
  local range = replace_range(line, row1, col0, mode)
  local now = util.now_ms()
  local rescan_ms = self.opts.rescan_ms or 5000

  local function build_and_send(files)
    self._cache.files = files
    self._cache.when = now

    local base = util.buf_dir()
    local items = {}

    for _, abs in ipairs(files) do
      local rel = util.relative_path(abs, base)
      local title = markdown.title_from_path(rel)
      local new_text = want_url and rel or markdown.link_for_path(rel, { wrap_spaces = false })

      items[#items + 1] = {
        label = title,
        kind = KIND_TEXT,
        detail = rel,
        filterText = table.concat({ title, rel, util.basename_noext(rel) }, " "),
        textEdit = {
          newText = new_text,
          range = range,
        },
      }
    end

    callback({ items = items, is_incomplete_forward = false, is_incomplete_backward = false })
  end

  if #self._cache.files == 0 or (now - self._cache.when) > rescan_ms then
    self:_scan_files(build_and_send)
  else
    build_and_send(self._cache.files)
  end

  return function() end
end

return M
