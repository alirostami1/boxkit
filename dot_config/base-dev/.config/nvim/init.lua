vim.g.mapleader = " "

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
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
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

local ui2_ok, ui2 = pcall(require, "vim._core.ui2")
if ui2_ok then
  ui2.enable({})
end

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

-- WARNING CONFLICT: <leader>d is also mapped to diagnostics float in LSP keys below.
-- delete without overwriting clipboard
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

-- do not lose visual selection when indenting
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- open file explorer
vim.keymap.set("n", "<leader>pp", "<cmd>Ex<cr>")

local treesitter_grammars = {
  "bash",
  "c",
  "cpp",
  "diff",
  "html",
  "javascript",
  "jsdoc",
  "json",
  "lua",
  "luadoc",
  "luap",
  "markdown",
  "latex",
  "markdown_inline",
  "python",
  "query",
  "regex",
  "rust",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "yaml",
  "go",
  "gomod",
  "gosum",
  "gowork",
  "gotmpl",
  "astro",
  "cmake",
  "make",
  "matlab",
  "nginx",
  "rasi",
  "sql",
  "arduino",
  "awk",
  "comment",
  "css",
  "dart",
  "desktop",
  "dockerfile",
  "gitcommit",
  "gitignore",
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
      require("nvim-treesitter").install(treesitter_grammars)
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
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
  { src = "https://github.com/ibhagwan/fzf-lua" },
  { src = "https://github.com/folke/trouble.nvim" },
  { src = "https://github.com/mfussenegger/nvim-lint" },
  { src = "https://github.com/stevearc/conform.nvim" },
  { src = "https://github.com/echasnovski/mini.comment" },
  { src = "https://github.com/tpope/vim-fugitive" },
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "4916d6592ede8c07973490d9322f187e07dfefac" },
  { src = "https://github.com/alirostami1/dpview" },
}, { confirm = false })

vim.keymap.set("n", "<leader>u", "<cmd>Undotree<cr>", { desc = "Toggle undotree" })

local vscode_loader = require("luasnip.loaders.from_vscode")
vscode_loader.lazy_load()
vscode_loader.load({
  paths = { vim.fn.stdpath("config") .. "/snippets" },
})

require("mason").setup()

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

vim.diagnostic.config({
  virtual_text = true,
  update_in_insert = false,
  underline = true,
})

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_deep_extend("force", capabilities, require("blink.cmp").get_lsp_capabilities({}, false))

vim.lsp.config("*", {
  capabilities = capabilities,
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

vim.lsp.enable(lsp_servers)

local mason_filetypes_by_package = {
  ["astro-language-server"] = { "astro" },
  ["bash-language-server"] = { "bash", "sh", "zsh" },
  clangd = { "c", "cpp" },
  gopls = { "go", "gomod", "gosum", "gotmpl", "gowork" },
  ["golangci-lint"] = { "go" },
  gofumpt = { "go" },
  hadolint = { "dockerfile" },
  ["eslint_d"] = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  ["json-lsp"] = { "json", "jsonc" },
  ["lua-language-server"] = { "lua" },
  ["markdownlint-cli2"] = { "markdown" },
  prettier = { "javascript", "javascriptreact", "json", "jsonc", "markdown", "typescript", "typescriptreact" },
  prettierd = { "javascript", "javascriptreact", "json", "jsonc", "markdown", "typescript", "typescriptreact" },
  pyright = { "python" },
  ruff = { "python" },
  ["rust-analyzer"] = { "rust" },
  selene = { "lua" },
  shfmt = { "bash", "sh", "zsh" },
  stylua = { "lua" },
  ["tailwindcss-language-server"] = { "astro", "css", "html", "javascriptreact", "typescriptreact" },
  templ = { "templ" },
  ["typescript-language-server"] = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  ["yaml-language-server"] = { "yaml" },
  yamlfmt = { "yaml" },
  yamllint = { "yaml" },
}

require("base_dev.mason_tools").setup({
  filetypes_by_package = mason_filetypes_by_package,
})

local fzf_lua = require("fzf-lua")
fzf_lua.setup({
  keymap = {
    fzf = {
      ["ctrl-q"] = "select-all+accept",
    },
  },
})

vim.keymap.set("n", "<leader>/", fzf_lua.live_grep, { desc = "Grep" })
vim.keymap.set("n", "<leader>ff", fzf_lua.files, { desc = "Find Files" })
vim.keymap.set("n", "<leader>fg", fzf_lua.git_files, { desc = "Find Git Files" })
vim.keymap.set("n", "<leader>sw", fzf_lua.grep_cword, { desc = "Grep word under cursor" })
vim.keymap.set("n", "<leader>sW", fzf_lua.grep_cWORD, { desc = "Grep WORD under cursor" })
vim.keymap.set({ "v", "x" }, "<leader>sW", fzf_lua.grep_visual, { desc = "Visual selection or word" })
vim.keymap.set("n", "<leader>grr", fzf_lua.lsp_references, { nowait = true, desc = "References" })

vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
vim.keymap.set("n", "]t", function()
  require("trouble").next({ skip_groups = true, jump = true })
end, { desc = "Previous Trouble" })
vim.keymap.set("n", "[t", function()
  require("trouble").prev({ skip_groups = true, jump = true })
end, { desc = "Next Trouble" })

local lint = require("lint")
lint.linters_by_ft = {
  dockerfile = { "hadolint" },
  go = { "golangcilint" },
  javascript = { "eslint_d" },
  javascriptreact = { "eslint_d" },
  lua = { "selene" },
  markdown = { "markdownlint-cli2" },
  typescript = { "eslint_d" },
  typescriptreact = { "eslint_d" },
  yaml = { "yamllint" },
}

local lint_augroup = vim.api.nvim_create_augroup("linting", { clear = true })
vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
  group = lint_augroup,
  callback = function()
    lint.try_lint()
  end,
})

local conform = require("conform")
conform.setup({
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff" },
    javascript = { "prettierd", "prettier", stop_after_first = true },
    json = { "prettierd", "prettier", stop_after_first = true },
    markdown = { "prettierd", "prettier", stop_after_first = true },
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
vim.keymap.set("n", "<leader>fo", function()
  conform.format({ async = true })
end, { desc = "Format buffer" })

vim.keymap.set("n", "<leader>gg", ":Git<CR>")
vim.keymap.set("n", "<leader>gB", ":Git blame<CR>", { desc = "Git blame" })
vim.keymap.set("n", "<leader>gd", ":Gvdiffsplit<CR>", { desc = "Git diff" })
vim.keymap.set("n", "<leader>gpp", ":Git push<CR>", { desc = "Git push" })
vim.keymap.set("n", "<leader>gpt", ":Git push --follow-tags<CR>", { desc = "Git push with tags" })
vim.keymap.set("n", "<leader>gpu", ":Git pull<CR>", { desc = "Git pull" })

require("nvim-treesitter").install(treesitter_grammars)

require("dpview").setup({
  port = 8421,
  sidebar_collapsed = true,
  editor_file_sync = true,
  preview_theme = "github",
  cursor_seek = true,
  latex_enabled = true,
  typst_preview_theme = false,
  markdown_frontmatter_visible = true,
  markdown_frontmatter_expanded = true,
  markdown_frontmatter_title = true,
  auto_start = true,
  auto_open_browser = false,
  log_level = "info",
})
