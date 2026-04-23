vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.g.have_nerd_font = true

vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25
vim.g.omni_sql_no_default_maps = 1

vim.opt.guicursor = "i:block"

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- dont show the mode as it is already in the statusline
vim.opt.showmode = false

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.inccommand = "split"

vim.opt.termguicolors = true

vim.opt.scrolloff = 10
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50
vim.opt.timeoutlen = 300

vim.opt.colorcolumn = "80"

vim.opt.mouse = ""

vim.cmd("colorscheme habamax")

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- paste without overwriting clipboard
vim.keymap.set("x", "<leader>p", [["_dP]])

-- yank to system clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
-- Yank whole line to system clipboard
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- do not lose visual selection when indenting
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- open file explorer
vim.keymap.set("n", "<leader>pp", "<cmd>Ex<cr>")

-- open all folds upon document open
vim.o.foldlevel = 99
-- fold syntax highlight see https://github.com/neovim/neovim/pull/20750
vim.o.foldtext = ""
vim.o.fillchars = "fold: "

---@param reg string
local function yank_line_diagnostics(reg)
  local diags = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })
  local n_diags = #diags
  if n_diags == 0 then
    vim.notify("No diagnostics found in current line", vim.log.levels.WARN)
    return
  end
  local combined_diag = table.concat(
    vim.tbl_map(function(diag)
      return diag.message
    end, diags),
    "\n"
  )
  vim.fn.setreg(reg, combined_diag)
  vim.fn.setreg(vim.v.register, combined_diag)
  vim.notify(string.format("Yanked diagnostic message '%s'", combined_diag), vim.log.levels.INFO)
end
-- copy diagnostics messages
vim.keymap.set("n", "yd", function()
  yank_line_diagnostics('"')
end, { desc = "Yank diagnostic messages on current line" })
vim.keymap.set("n", "<leader>yd", function()
  yank_line_diagnostics("+")
end, { desc = "Yank diagnostic messages on current line" })

vim.keymap.set({ "n", "x" }, "<Leader>xl", function()
  vim.diagnostic.setloclist()
end, { desc = "Show document diagnostics" })
vim.keymap.set({ "n", "x" }, "<Leader>xf", function()
  vim.diagnostic.setqflist()
end, { desc = "Show workspace diagnostics" })

vim.diagnostic.config({
  severity_sort = true,
  virtual_text = true,
  update_in_insert = false,
  underline = true,
})

-- enable ui2 if available
local ui2_ok, ui2 = pcall(require, "vim._core.ui2")
if ui2_ok then
  ui2.enable({})
end

-- start session
require("aros.session").setup()

-- highlight yanked section
local highlight_yank_augroup = vim.api.nvim_create_augroup("HighlightYank", {})
vim.api.nvim_create_autocmd("TextYankPost", {
  group = highlight_yank_augroup,
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({
      higroup = "IncSearch",
      timeout = 40,
    })
  end,
})

local lsp_servers = {
  "bashls",
  "gopls",
  "lua_ls",
  "pyright",
  "rust_analyzer",
  "templ",
  "ts_ls",
  "yamlls",
  "jsonls",
  "clangd",
  "astro",
  "tailwindcss",
}

local parsers = {
  "vim",
  "vimdoc",
  "query",
  "bash",
  "c",
  "cpp",
  "html",
  "python",
  "rust",
  "tsx",
  "go",
  "javascript",
  "typescript",
  "jsdoc",
  "lua",
  "luadoc",
  "json",
  "yaml",
  "toml",
  "markdown",
  "latex",
  "markdown_inline",
  "gotmpl",
  "astro",
  "sql",
  "css",
  "dart",
}

local function pack_hooks(ev)
  local name = ev.data.spec.name
  local kind = ev.data.kind

  if kind ~= "install" and kind ~= "update" then
    return
  end

  if name == "LuaSnip" then
    vim.system({ "make", "install_jsregexp" }, { cwd = ev.data.path }):wait()
  elseif name == "nvim-treesitter" then
    if not ev.data.active then
      vim.cmd.packadd("nvim-treesitter")
    end
    pcall(function()
      require("nvim-treesitter").install(parsers)
    end)
  end
end

vim.api.nvim_create_autocmd("PackChanged", {
  callback = pack_hooks,
})

vim.cmd.packadd("nvim.undotree")
vim.cmd.packadd("nvim.difftool")

vim.pack.add({
  { src = "https://github.com/rafamadriz/friendly-snippets" },
  { src = "https://github.com/L3MON4D3/LuaSnip", version = vim.version.range("2.0.0 - 3.0.0") },
  { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("1.0.0 - 2.0.0") },
  { src = "https://github.com/folke/lazydev.nvim" },
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/ibhagwan/fzf-lua" },
  { src = "https://github.com/mfussenegger/nvim-lint" },
  { src = "https://github.com/stevearc/conform.nvim" },
  { src = "https://github.com/echasnovski/mini.comment" },
  { src = "https://github.com/tpope/vim-fugitive" },
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "4916d6592ede8c07973490d9322f187e07dfefac" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects" },
  { src = "https://github.com/carlos-algms/agentic.nvim" },
})

-- plugin: undotree
vim.keymap.set("n", "<leader>u", "<cmd>Undotree<cr>", { desc = "Toggle undotree" })

-- plugin: luasnip
local snippets_augroup = vim.api.nvim_create_augroup("SnippetLoad", { clear = true })
vim.api.nvim_create_autocmd("BufEnter", {
  group = snippets_augroup,
  callback = function()
    local vscode_loader = require("luasnip.loaders.from_vscode")
    vscode_loader.lazy_load()
    vscode_loader.load({
      paths = { vim.fn.stdpath("config") .. "/snippets" },
    })
  end,
})

-- plugin: mason
require("mason").setup()
require("aros.mason_tools").setup({})

-- symbol navigation
require("aros.symbols").setup()

-- plugin: blink
require("blink.cmp").setup({
  keymap = { preset = "default" },
  appearance = {},
  snippets = {
    preset = "luasnip",
  },
  completion = {
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 250,
      treesitter_highlighting = true,
      window = { border = "rounded" },
    },
    trigger = {
      show_on_keyword = true,
      show_on_trigger_character = true,
    },
    list = {
      selection = {
        auto_insert = false,
      },
    },
    ghost_text = {
      enabled = false,
    },
    menu = {
      border = "rounded",
      draw = {
        columns = { { "label", "label_description", gap = 1 }, { "kind_icon" } },
      },
    },
  },
  signature = {
    enabled = false,
  },
  sources = {
    default = { "lsp", "snippets", "path", "buffer" },
  },
  fuzzy = { implementation = "prefer_rust_with_warning" },
})

-- plugin: lazydev
require("lazydev").setup({
  library = {
    { path = "${3rd}/luv/library", words = { "vim%.uv" } },
  },
})

-- lsp
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_deep_extend("force", capabilities, require("blink.cmp").get_lsp_capabilities({}, false))
vim.lsp.config("*", {
  capabilities = capabilities,
})

vim.lsp.enable(lsp_servers)

local lsp_augroup = vim.api.nvim_create_augroup("LspAttach", {})
vim.api.nvim_create_autocmd("LspAttach", {
  group = lsp_augroup,
  callback = function(e)
    local opts = { buffer = e.buf }
    vim.keymap.set("n", "gd", function()
      vim.lsp.buf.definition()
    end, opts)
  end,
})

-- plugin fzf-lua
local fzf_lua = require("fzf-lua")
vim.keymap.set("n", "<leader>fg", fzf_lua.live_grep, { desc = "Grep" })
vim.keymap.set("n", "<leader>ff", fzf_lua.files, { desc = "Find Files" })
vim.keymap.set("n", "<leader>fs", fzf_lua.lsp_document_symbols, { desc = "Find LSP Document Symbols" })
vim.keymap.set("n", "<leader>fw", fzf_lua.grep_cword, { desc = "Grep word under cursor" })
vim.keymap.set("n", "<leader>fW", fzf_lua.grep_cWORD, { desc = "Grep WORD under cursor" })
vim.keymap.set({ "v", "x" }, "<leader>fv", fzf_lua.grep_visual, { desc = "Visual selection or word" })

-- plugin nvim-lint
local lint = require("lint")
lint.linters_by_ft = {
  dockerfile = { "hadolint" },
  go = { "golangcilint" },
  javascript = { "biomejs" },
  javascriptreact = { "biomejs" },
  css = { "biomejs" },
  graphql = { "biomejs" },
  json = { "biomejs" },
  lua = { "selene" },
  markdown = { "markdownlint-cli2" },
  typescript = { "biomejs" },
  typescriptreact = { "biomejs" },
  yaml = { "yamllint" },
}

local lint_augroup = vim.api.nvim_create_augroup("linting", { clear = true })
vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
  group = lint_augroup,
  callback = function()
    lint.try_lint()
  end,
})

-- plugin: conform.nvim
local conform = require("conform")
conform.setup({
  formatters_by_ft = {
    ["_"] = { "trim_whitespace" },
    c = { "clang-format" },
    cpp = { "clang-format" },
    lua = { "stylua" },
    python = { "ruff" },
    javascript = { "biome", "biome-organize-imports" },
    typescript = { "biome", "biome-organize-imports" },
    javascriptreact = { "biome", "biome-organize-imports" },
    typescriptreact = { "biome", "biome-organize-imports" },
    css = { "biome" },
    json = { "biome" },
    markdown = { "rumdl" },
    go = { "gofumpt", "gofmt", stop_after_first = true },
    rust = { "rustfmt" },
    sh = { "shfmt" },
    yaml = { "yamlfmt" },
  },
  default_format_opts = {
    lsp_format = "fallback",
  },
  format_on_save = { timeout_ms = 500 },
  formatters = {
    shfmt = {
      prepend_args = { "-i", "2" },
    },
  },
})

vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

vim.keymap.set("n", "<leader>gq", function()
  conform.format({ async = true })
end, { desc = "Format buffer" })

-- plugin: vim-fugitive
vim.keymap.set("n", "<leader>gg", ":Git<CR>")
vim.keymap.set("n", "<leader>gb", ":Git blame<CR>", { desc = "Git blame" })
vim.keymap.set("n", "<leader>gd", ":Gvdiffsplit<CR>", { desc = "Git diff" })
vim.keymap.set("n", "<leader>gp", ":Git push<CR>", { desc = "Git push" })

-- plugin: nvim-treesitter
local treesitter_augroup = vim.api.nvim_create_augroup("TreesitterStart", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
  group = treesitter_augroup,
  callback = function(ev)
    if vim.bo.buftype ~= "" then
      return
    end

    local successful = pcall(vim.treesitter.start, ev.buf)
    if not successful then
      return
    end
    vim.wo[0][0].fdm = "expr"
    vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  group = treesitter_augroup,
  callback = function()
    require("nvim-treesitter").install(parsers)
  end,
})

-- plugin: nvim-treesitter-textobjects
require("nvim-treesitter-textobjects").setup({
  select = {
    enable = true,
    lookahead = true,
  },
})
vim.keymap.set({ "x", "o" }, "af", function()
  require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects")
end)
vim.keymap.set({ "x", "o" }, "if", function()
  require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects")
end)

-- plugin: agentic.nvim
require("agentic").setup({ provider = "codex-acp" })

vim.keymap.set({ "n", "v", "i" }, "<C-\\>", function()
  require("agentic").toggle()
end, { desc = "Toggle Agentic Chat" })
vim.keymap.set({ "n", "v" }, "<C-'>", function()
  require("agentic").add_selection_or_file_to_context()
end, { desc = "Add file or selection to Agentic to Context" })
vim.keymap.set({ "n", "v", "i" }, "<C-,>", function()
  require("agentic").new_session()
end, { desc = "New Agentic Session" })
