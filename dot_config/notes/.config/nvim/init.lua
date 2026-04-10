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

-- delete without overwriting clipboard
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

-- do not lose visual selection when indenting
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- open file explorer
vim.keymap.set("n", "<leader>pp", "<cmd>Ex<cr>")

local notes_fzf_links = require("notes.features.fzf_links")
local notes_new_from_visual = require("notes.features.new_from_visual")
local notes_task_toggle = require("notes.features.task_toggle")

notes_new_from_visual.setup_user_command()

local treesitter_grammars = {
  "diff",
  "html",
  "json",
  "lua",
  "luadoc",
  "luap",
  "markdown",
  "markdown_inline",
  "typst",
  "query",
  "regex",
  "toml",
  "yaml",
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
  { src = "https://github.com/alirostami1/dpview" },
  { src = "https://github.com/tpope/vim-fugitive" },
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
  { src = "https://github.com/ibhagwan/fzf-lua" },
  { src = "https://github.com/echasnovski/mini.comment" },
  { src = "https://github.com/stevearc/conform.nvim" },
}, { confirm = false })

vim.keymap.set("n", "<leader>u", "<cmd>Undotree<cr>", { desc = "Open undotree" })

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
    per_filetype = {
      markdown = { inherit_defaults = true, "mdlinks" },
    },
    providers = {
      mdlinks = {
        name = "MD Links",
        module = "notes.features.blink_mdlinks",
        opts = {
          roots = { vim.fn.expand("~/notes") },
          glob = "*.md",
          rescan_ms = 5000,
        },
        min_keyword_length = 1,
        score_offset = 10,
      },
      snippets = {
        score_offset = 100,
      },
    },
  },
  fuzzy = { implementation = "prefer_rust_with_warning" },
})

require("dpview").setup({
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

vim.keymap.set("n", "<leader>gg", ":Git<CR>")
vim.keymap.set("n", "<leader>gc", function()
  local commit_message = vim.fn.input("commit message > ")
  vim.api.nvim_cmd({
    cmd = "Git",
    args = { "commit", "-m", commit_message },
  }, {})
end)
vim.keymap.set("n", "<leader>gB", ":Git blame<CR>", { desc = "Git blame" })
vim.keymap.set("n", "<leader>gd", ":Gvdiffsplit<CR>", { desc = "Git diff" })
vim.keymap.set("n", "<leader>gP", ":Git push<CR>", { desc = "Git push" })
vim.keymap.set("n", "<leader>gp", ":Git pull<CR>", { desc = "Git pull" })
vim.keymap.set("n", "<leader>ga", function()
  vim.cmd("Git add .")
  vim.print("git: files staged")
end, { desc = "Git stage all files" })

require("gitsigns").setup()

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
vim.lsp.enable({
  "marksman",
  "tinymist",
})

local mason_filetypes_by_package = {
  marksman = { "markdown" },
  prettier = { "json", "markdown" },
  prettierd = { "json", "markdown" },
  tinymist = { "typst" },
}

require("notes.mason_tools").setup({
  filetypes_by_package = mason_filetypes_by_package,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, { buffer = ev.buf })
  end,
})

vim.keymap.set("n", "<leader>lr", "<cmd>lsp restart<CR>", { desc = "Restart LSP" })
vim.keymap.set("n", "<leader>li", "<cmd>checkhealth vim.lsp<CR>", { desc = "LSP info" })
vim.keymap.set("n", "]d", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next diagnostic" })
vim.keymap.set("n", "[d", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Previous diagnostic" })
vim.keymap.set("n", "<leader>ld", vim.diagnostic.open_float, { desc = "Line diagnostics" })

require("markdown_preview").setup({
  port = 8421,
  open_browser = false,
  debounce_ms = 300,
})

require("render-markdown").setup({})

local fzf_lua = require("fzf-lua")
fzf_lua.setup({
  keymap = {
    fzf = {
      ["ctrl-q"] = "select-all+accept",
    },
  },
})

vim.keymap.set("n", "<leader>/", fzf_lua.live_grep, { desc = "Grep" })
vim.keymap.set("n", "<leader>fb", fzf_lua.buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>ff", fzf_lua.files, { desc = "Find Files" })
vim.keymap.set("n", "<leader>fg", fzf_lua.git_files, { desc = "Find Git Files" })
vim.keymap.set("n", "<leader>sw", fzf_lua.grep_cword, { desc = "Grep word under cursor" })
vim.keymap.set("n", "<leader>sW", fzf_lua.grep_cWORD, { desc = "Grep WORD under cursor" })
vim.keymap.set({ "v", "x" }, "<leader>sv", fzf_lua.grep_visual, { desc = "Visual selection or word" })
vim.keymap.set("n", "<leader>sk", fzf_lua.keymaps, { desc = "Keymaps" })
vim.keymap.set("n", "<leader>sl", fzf_lua.loclist, { desc = "Location List" })
vim.keymap.set("n", "<leader>sq", fzf_lua.quickfix, { desc = "Quickfix List" })
vim.keymap.set("n", "grd", fzf_lua.lsp_definitions, { desc = "Goto Definition" })
vim.keymap.set("n", "grD", fzf_lua.lsp_declarations, { desc = "Goto Declaration" })
vim.keymap.set("n", "grr", fzf_lua.lsp_references, { nowait = true, desc = "References" })
vim.keymap.set("n", "gri", fzf_lua.lsp_implementations, { desc = "Goto Implementation" })
vim.keymap.set("n", "grt", fzf_lua.lsp_type_definitions, { desc = "Goto T[y]pe Definition" })
vim.keymap.set("n", "gO", fzf_lua.lsp_document_symbols, { desc = "LSP Document Symbols" })
vim.keymap.set("n", "go", fzf_lua.lsp_workspace_symbols, { desc = "LSP Workspace Symbols" })

require("mini.comment").setup()

local conform = require("conform")
conform.setup({
  formatters_by_ft = {
    json = { "prettierd", "prettier", stop_after_first = true },
    markdown = { "prettierd", "prettier", stop_after_first = true },
  },
  default_format_opts = {
    lsp_format = "fallback",
  },
  format_on_save = { timeout_ms = 500 },
})
vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
vim.keymap.set("n", "<leader>f", function()
  conform.format({ async = true })
end, { desc = "Format buffer" })

require("nvim-treesitter").install(treesitter_grammars)

require("typst-preview").setup({
  open_cmd = "bash -lc 'GIO_USE_PORTALS=1 gio open \"$1\" 2>/dev/null' _ %s",
  port = 46241,
})

local notes_filetypes = vim.api.nvim_create_augroup("NotesFiletypes", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = notes_filetypes,
  pattern = "markdown",
  callback = function(args)
    if vim.b[args.buf].notes_markdown_ftplugin_loaded then
      return
    end
    vim.b[args.buf].notes_markdown_ftplugin_loaded = true

    vim.opt_local.conceallevel = 0
    vim.opt_local.spelllang = "en_us"
    vim.opt_local.spell = true

    pcall(vim.treesitter.start, args.buf)
    vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.wo.foldmethod = "expr"
    vim.opt_local.foldlevel = 99
    vim.opt_local.foldlevelstart = 99

    notes_fzf_links.setup_buffer_keymaps(args.buf)
    notes_new_from_visual.setup_buffer_keymaps(args.buf)

    vim.keymap.set("n", "<leader>tt", function()
      vim.api.nvim_put({ vim.fn.strftime("%H:%M") }, "c", true, true)
    end, { buffer = args.buf, desc = "Insert current time" })

    vim.keymap.set("n", "<leader>td", function()
      vim.api.nvim_put({ vim.fn.strftime("%Y-%m-%d") }, "c", true, true)
    end, { buffer = args.buf, desc = "Insert current date" })

    vim.keymap.set("n", "<leader>t", function()
      notes_task_toggle.toggle_task_at_cursor()
    end, {
      buffer = args.buf,
      desc = "Toggle markdown task",
    })

    vim.keymap.set("n", "<leader>jt", function()
      vim.cmd([[silent! lvimgrep /^\s*-\s\[\s\]\s.\+/j %]])
      vim.cmd("lopen")
    end, {
      buffer = args.buf,
      desc = "List unchecked todos in current markdown file",
    })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = notes_filetypes,
  pattern = "typst",
  callback = function(args)
    if vim.b[args.buf].notes_typst_ftplugin_loaded then
      return
    end
    vim.b[args.buf].notes_typst_ftplugin_loaded = true

    vim.opt_local.spelllang = "en_us"
    vim.opt_local.spell = true
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true

    pcall(vim.treesitter.start, args.buf)
    vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.wo.foldmethod = "expr"
    vim.opt_local.foldlevel = 99
    vim.opt_local.foldlevelstart = 99

    vim.keymap.set("n", "<leader>tt", function()
      vim.api.nvim_put({ vim.fn.strftime("%H:%M") }, "c", true, true)
    end, { buffer = args.buf, desc = "Insert current time" })

    vim.keymap.set("n", "<leader>td", function()
      vim.api.nvim_put({ vim.fn.strftime("%Y-%m-%d") }, "c", true, true)
    end, { buffer = args.buf, desc = "Insert current date" })
  end,
})
