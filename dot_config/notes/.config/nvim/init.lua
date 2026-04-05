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

local uv = vim.uv or vim.loop

local notes_fzf_links = require("notes.features.fzf_links")
local notes_new_from_visual = require("notes.features.new_from_visual")
local notes_task_toggle = require("notes.features.task_toggle")

notes_new_from_visual.setup_user_command()

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not uv.fs_stat(lazypath) then
  local clone_output = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.notify("lazy.nvim bootstrap failed:\n" .. vim.trim(clone_output), vim.log.levels.ERROR)
    return
  end
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
  {
    "folke/lazy.nvim",
    version = "*",
  },
  {
    "saghen/blink.cmp",
    event = "InsertEnter",
    version = "1.*",
    dependencies = { "L3MON4D3/LuaSnip", version = "v2.*" },
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
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
    },
  },
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    build = "make install_jsregexp",
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function()
      local vscode_loader = require("luasnip.loaders.from_vscode")

      vscode_loader.lazy_load()
      vscode_loader.load({
        paths = { vim.fn.stdpath("config") .. "/snippets" },
      })
    end,
  },
  {
    "tpope/vim-fugitive",
    event = "VeryLazy",
    cmd = {
      "Git",
    },
    keys = {
      { mode = "n", "<leader>gg", ":Git<CR>" },
      {
        mode = "n",
        "<leader>gc",
        function()
          local commit_message = vim.fn.input("commit message > ")
          vim.api.nvim_cmd({
            cmd = "Git",
            args = { "commit", "-m", commit_message },
          }, {})
        end,
      },
      { mode = "n", "<leader>gB", ":Git blame<CR>", desc = "Git blame" },
      { mode = "n", "<leader>gd", ":Gvdiffsplit<CR>", desc = "Git diff" },
      { mode = "n", "<leader>gP", ":Git push<CR>", desc = "Git push" },
      { mode = "n", "<leader>gp", ":Git pull<CR>", desc = "Git pull" },
      {
        mode = "n",
        "<leader>ga",
        function()
          vim.cmd("Git add .")
          vim.print("git: files staged")
        end,
        desc = "Git stage all files",
      },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    event = "VeryLazy",
    config = function()
      require("gitsigns").setup()
    end,
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile", "BufWritePre" },
    dependencies = {
      "saghen/blink.cmp",
    },
    keys = {
      { mode = { "n" }, "<leader>lr", "<cmd>LspRestart<CR>" },
      { mode = { "n" }, "<leader>li", "<cmd>LspInfo<CR>" },
      { mode = "n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>" },
      { mode = "n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>" },
      { mode = "n", "<leader>ld", "<cmd>lua vim.diagnostic.open_float()<CR>" },
    },
    opts = {
      capabilities = {
        workspace = {
          fileOperations = {
            didRename = true,
            willRename = true,
          },
        },
      },
      servers = {
        marksman = {},
        tinymist = {
          settings = {
            formatterMode = "typstyle",
          },
        },
      },
    },
    config = function(_, opts)
      vim.diagnostic.config({
        virtual_text = true,
        update_in_insert = false,
        underline = true,
      })

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend("force", capabilities, require("blink.cmp").get_lsp_capabilities({}, false))
      for server, server_opts in pairs(opts.servers) do
        server_opts.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server_opts.capabilities or {})
        vim.lsp.config(server, server_opts)
        vim.lsp.enable(server)
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          local keymap_options = { buffer = ev.buf }
          vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, keymap_options)
        end,
      })
    end,
  },
  {
    "selimacerbas/markdown-preview.nvim",
    dependencies = { "selimacerbas/live-server.nvim" },
    config = function()
      require("markdown_preview").setup({
        port = 8421,
        open_browser = false,
        debounce_ms = 300,
      })
    end,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
  },
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      keymap = {
        fzf = {
          ["ctrl-q"] = "select-all+accept",
        },
      },
    },
    keys = {
      {
        "<leader>/",
        function()
          FzfLua.live_grep()
        end,
        desc = "Grep",
      },
      {
        "<leader>fb",
        function()
          FzfLua.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>ff",
        function()
          FzfLua.files()
        end,
        desc = "Find Files",
      },
      {
        "<leader>fg",
        function()
          FzfLua.git_files()
        end,
        desc = "Find Git Files",
      },
      {
        "<leader>sw",
        function()
          FzfLua.grep_cword()
        end,
        desc = "Grep word under cursor",
        mode = { "n" },
      },
      {
        "<leader>sW",
        function()
          FzfLua.grep_cWORD()
        end,
        desc = "Grep WORD under cursor",
        mode = { "n" },
      },
      {
        "<leader>sv",
        function()
          FzfLua.grep_visual()
        end,
        desc = "Visual selection or word",
        mode = { "v", "x" },
      },
      {
        "<leader>sk",
        function()
          FzfLua.keymaps()
        end,
        desc = "Keymaps",
      },
      {
        "<leader>sl",
        function()
          FzfLua.loclist()
        end,
        desc = "Location List",
      },
      {
        "<leader>sq",
        function()
          FzfLua.quickfix()
        end,
        desc = "Quickfix List",
      },
      {
        "grd",
        function()
          FzfLua.lsp_definitions()
        end,
        desc = "Goto Definition",
      },
      {
        "grD",
        function()
          FzfLua.lsp_declarations()
        end,
        desc = "Goto Declaration",
      },
      {
        "grr",
        function()
          FzfLua.lsp_references()
        end,
        nowait = true,
        desc = "References",
      },
      {
        "gri",
        function()
          FzfLua.lsp_implementations()
        end,
        desc = "Goto Implementation",
      },
      {
        "grt",
        function()
          FzfLua.lsp_type_definitions()
        end,
        desc = "Goto T[y]pe Definition",
      },
      {
        "gO",
        function()
          FzfLua.lsp_document_symbols()
        end,
        desc = "LSP Document Symbols",
      },
      {
        "go",
        function()
          FzfLua.lsp_workspace_symbols()
        end,
        desc = "LSP Workspace Symbols",
      },
    },
  },
  {
    "echasnovski/mini.comment",
    version = "*",
    keys = {
      { "gc", mode = { "n", "v" }, desc = "toggle comment line" },
    },
    config = function()
      require("mini.comment").setup()
    end,
  },
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>f",
        function()
          require("conform").format({ async = true })
        end,
        mode = "n",
        desc = "Format buffer",
      },
    },
    ---@module "conform"
    ---@type conform.setupOpts
    opts = {
      formatters_by_ft = {
        json = { "prettierd", "prettier", stop_after_first = true },
        markdown = { "prettierd", "prettier", stop_after_first = true },
      },
      default_format_opts = {
        lsp_format = "fallback",
      },
      format_on_save = { timeout_ms = 500 },
    },
    init = function()
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
  },
  {
    "mbbill/undotree",
    event = "VeryLazy",
    keys = {
      { mode = "n", "<leader>u", ":UndotreeToggle<CR>", desc = "Toggle undotree" },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "VeryLazy" },
    branch = "main",
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    opts = {
      grammars = {
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
      },
    },
    config = function(_, opts)
      require("nvim-treesitter").install(opts.grammars)
    end,
  },
  {
    "chomosuke/typst-preview.nvim",
    ft = "typst",
    version = "1.*",
    opts = {
      open_cmd = "bash -lc 'GIO_USE_PORTALS=1 gio open \"$1\" 2>/dev/null' _ %s",
      port = 46241,
    },
  },
}

require("lazy").setup(plugins, {
  change_detection = {
    notify = false,
  },
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
