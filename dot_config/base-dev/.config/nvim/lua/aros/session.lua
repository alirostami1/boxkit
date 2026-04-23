local M = {}

local session_root = vim.fs.joinpath(vim.fn.stdpath("state"), "sessions")

local function current_workspace()
  local cwd = vim.fn.getcwd()
  return vim.uv.fs_realpath(cwd) or cwd
end

local function session_name(workspace)
  local basename = vim.fs.basename(workspace)
  local hash = vim.fn.sha256(workspace):sub(1, 12)
  return string.format("%s-%s.vim", basename, hash)
end

function M.session_file(workspace)
  workspace = workspace or current_workspace()
  return vim.fs.joinpath(session_root, session_name(workspace))
end

function M.save()
  local ok, err = pcall(vim.fn.mkdir, session_root, "p")
  if not ok then
    vim.notify("Failed to create session directory: " .. err, vim.log.levels.WARN)
    return
  end

  local session_file = M.session_file()
  local escaped = vim.fn.fnameescape(session_file)

  vim.cmd("silent! mksession! " .. escaped)
end

function M.restore()
  local session_file = M.session_file()

  if vim.fn.filereadable(session_file) == 0 then
    return false
  end

  vim.cmd("silent! source " .. vim.fn.fnameescape(session_file))
  return true
end

function M.setup()
  vim.opt.sessionoptions = {
    "buffers",
    "curdir",
    "folds",
    "help",
    "localoptions",
    "tabpages",
    "terminal",
    "winsize",
  }

  vim.api.nvim_create_user_command("SaveWorkspaceSession", function()
    M.save()
  end, { desc = "Save workspace session under XDG state" })

  vim.api.nvim_create_user_command("RestoreWorkspaceSession", function()
    M.restore()
  end, { desc = "Restore workspace session from XDG state" })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = M.save,
  })
end

return M
