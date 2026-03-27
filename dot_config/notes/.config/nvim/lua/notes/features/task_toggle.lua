local M = {}

function M.toggle_task_at_cursor()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local line = vim.api.nvim_get_current_line()
  local new_line = line

  if line:match("^%s*[%-%*%+] %[%s%]") then
    new_line = line:gsub("^(%s*[%-%*%+] )%[%s%]", "%1[x]", 1)
  elseif line:match("^%s*[%-%*%+] %[[xX]%]") then
    new_line = line:gsub("^(%s*[%-%*%+] )%[[xX]%]", "%1[ ]", 1)
  else
    return
  end

  if new_line ~= line then
    vim.api.nvim_buf_set_lines(0, row, row + 1, false, { new_line })
  end
end

return M
