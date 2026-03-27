local util = require("notes.util")

local M = {}

function M.title_from_path(path_str)
  local base = util.basename_noext(path_str)
  base = base:gsub("[-_]+", " ")
  return util.title_case_words(base)
end

function M.link_for_path(path_str, opts)
  opts = opts or {}
  local text = opts.text or M.title_from_path(path_str)
  local url = path_str

  if opts.wrap_spaces ~= false and url:find("%s") then
    url = "<" .. url .. ">"
  end

  return ("[%s](%s)"):format(text, url)
end

return M
