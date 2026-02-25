local M = {}

local uv = vim.uv or vim.loop

function M.now_ms()
  return uv.now()
end

function M.normalize(path)
  if vim.fs and vim.fs.normalize then
    return vim.fs.normalize(path)
  end
  return (path:gsub("\\", "/"))
end

function M.buf_dir()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then
    return uv.cwd()
  end
  if vim.fs and vim.fs.dirname then
    return vim.fs.dirname(name)
  end
  return name:match("^(.*)/[^/]*$") or "."
end

function M.basename_noext(path_str)
  local base = path_str:match("([^/]+)$") or path_str
  return (base:gsub("%.[^%.]+$", ""))
end

function M.trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function M.collapse_ws(s)
  return M.trim((s:gsub("%s+", " ")))
end

function M.title_case_words(s)
  s = M.collapse_ws(s)
  local out = {}
  for w in s:gmatch("%S+") do
    if w:match("^%u%u+$") then
      out[#out + 1] = w
    else
      out[#out + 1] = w:sub(1, 1):upper() .. w:sub(2):lower()
    end
  end
  return table.concat(out, " ")
end

function M.slugify_markdown_filename(s)
  s = M.collapse_ws(s):lower()
  s = s:gsub("[_]+", " ")
  s = s:gsub("%s+", "-")
  s = s:gsub("[^a-z0-9%-]", "")
  s = s:gsub("%-+", "-")
  s = s:gsub("^%-+", ""):gsub("%-+$", "")
  if s == "" then
    s = "untitled"
  end
  if not s:match("%.md$") then
    s = s .. ".md"
  end
  return s
end

local function split_path(path)
  path = M.normalize(path)
  local parts = {}
  for part in path:gmatch("[^/]+") do
    parts[#parts + 1] = part
  end
  return parts
end

function M.relative_path(target, base)
  target = M.normalize(target)
  base = M.normalize(base)

  local target_parts = split_path(target)
  local base_parts = split_path(base)

  local i = 1
  while i <= #target_parts and i <= #base_parts and target_parts[i] == base_parts[i] do
    i = i + 1
  end

  local rel = {}
  for _ = i, #base_parts do
    rel[#rel + 1] = ".."
  end
  for j = i, #target_parts do
    rel[#rel + 1] = target_parts[j]
  end

  local path = table.concat(rel, "/")
  if path == "" then
    return "."
  end
  return path
end

function M.project_root(start_dir)
  if vim.fs and vim.fs.find and vim.fs.dirname then
    local git = vim.fs.find(".git", { path = start_dir, upward = true })[1]
    if git then
      return vim.fs.dirname(git)
    end
  end
  return uv.cwd()
end

return M
