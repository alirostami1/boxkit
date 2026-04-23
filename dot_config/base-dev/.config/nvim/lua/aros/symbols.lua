local M = {}

local target_kinds = {
  [vim.lsp.protocol.SymbolKind.Function] = true,
  [vim.lsp.protocol.SymbolKind.Method] = true,
  [vim.lsp.protocol.SymbolKind.Constructor] = true,
  [vim.lsp.protocol.SymbolKind.Class] = true,
}

local function is_target_kind(kind)
  return target_kinds[kind] == true
end

local function symbol_range(symbol)
  if symbol.location and symbol.location.range then
    return symbol.location.range
  end

  return symbol.range
end

local function collect_symbols(symbols, bufnr, items)
  for _, symbol in ipairs(symbols) do
    local range = symbol_range(symbol)
    if range and is_target_kind(symbol.kind) then
      table.insert(items, {
        bufnr = bufnr,
        lnum = range.start.line + 1,
        col = range.start.character + 1,
        text = symbol.name,
      })
    end

    if symbol.children and #symbol.children > 0 then
      collect_symbols(symbol.children, bufnr, items)
    end
  end
end

local function normalize_snippet(text)
  if not text then
    return ""
  end

  text = text:gsub("\n", " ")
  text = text:gsub("^%s+", "")
  text = text:gsub("%s+$", "")
  if #text > 80 then
    text = text:sub(1, 77) .. "..."
  end
  return text
end

local function is_ts_target_node(node_type)
  node_type = node_type:lower()
  return node_type:find("function", 1, true)
    or node_type:find("method", 1, true)
    or node_type:find("constructor", 1, true)
    or node_type:find("class", 1, true)
    or node_type:find("struct", 1, true)
    or node_type:find("impl", 1, true)
    or node_type:find("enum", 1, true)
    or node_type:find("trait", 1, true)
    or node_type:find("interface", 1, true)
end

local function collect_treesitter_symbols(bufnr)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok or not parser then
    return {}
  end

  local items = {}
  local trees = parser:parse()
  if not trees then
    return
  end

  local function visit(node)
    if is_ts_target_node(node:type()) then
      local sr, sc = node:start()
      local er, ec = node:end_()
      local text = vim.treesitter.get_node_text(node, bufnr)
      table.insert(items, {
        bufnr = bufnr,
        lnum = sr + 1,
        col = sc + 1,
        end_lnum = er + 1,
        end_col = ec + 1,
        text = normalize_snippet(text or node:type()),
      })
    end

    for i = 0, node:named_child_count() - 1 do
      visit(node:named_child(i))
    end
  end

  for _, tree in ipairs(trees) do
    visit(tree:root())
  end

  return items
end

local function open_loclist(items, title)
  if #items == 0 then
    vim.notify("no functions or classes found", vim.log.levels.INFO)
    return
  end

  vim.fn.setloclist(0, {}, "r", {
    title = title,
    items = items,
  })
  vim.cmd.lopen()
end

function M.open_loclist()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/documentSymbol" })
  if #clients == 0 then
    open_loclist(collect_treesitter_symbols(bufnr), "Functions / Classes")
    return
  end

  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
  }

  vim.lsp.buf_request(bufnr, "textDocument/documentSymbol", params, function(err, result)
    if err then
      open_loclist(collect_treesitter_symbols(bufnr), "Functions / Classes")
      return
    end

    if not result or vim.tbl_isempty(result) then
      open_loclist(collect_treesitter_symbols(bufnr), "Functions / Classes")
      return
    end

    local items = {}
    collect_symbols(result, bufnr, items)

    if #items == 0 then
      items = collect_treesitter_symbols(bufnr)
    end

    open_loclist(items, "Functions / Classes")
  end)
end

function M.setup()
  vim.keymap.set("n", "<leader>os", M.open_loclist, { desc = "Functions / classes loclist" })
end

return M
