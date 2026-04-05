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

-- WARNING CONFLICT: <leader>d is also mapped to diagnostics float in LSP keys below.
-- delete without overwriting clipboard
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

-- do not lose visual selection when indenting
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- open file explorer
vim.keymap.set("n", "<leader>pp", "<cmd>Ex<cr>")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local uv = vim.uv or vim.loop
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
  -- core
  {
    "folke/lazy.nvim",
    version = "*",
  },

  -- ai
  {
    "github/copilot.vim",
    event = { "VeryLazy" },
  },

  -- completion
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

  -- ui
  {
    "folke/todo-comments.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },

  -- go
  {
    "romus204/go-tagger.nvim",
    ft = "go",
    config = function()
      require("go-tagger").setup({
        skip_private = true,
      })
    end,
  },
  {
    "alirostami1/iferr.nvim",
    ft = "go",
    opts = {
      message = [[fmt.Errorf("failed to %w", err)]],
      map = "<leader>ie",
    },
  },

  -- lsp
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
      -- WARNING CONFLICT: <leader>d is also mapped to delete-without-yank above.
      { mode = "n", "<leader>d", "<cmd>lua vim.diagnostic.open_float()<CR>" },
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
        bashls = {},
        gopls = {
          settings = {
            gofumpt = true,
            codelenses = {
              gc_details = false,
              generate = true,
              regenerate_cgo = true,
              run_govulncheck = true,
              test = true,
              tidy = true,
              upgrade_dependency = true,
              vendor = true,
            },
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              compositeLiteralTypes = true,
              constantValues = true,
              functionTypeParameters = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
            analyses = {
              fieldalignment = true,
              nilness = true,
              unusedparams = true,
              unusedwrite = true,
              useany = true,
            },
            usePlaceholders = true,
            completeUnimported = true,
            staticcheck = true,
            directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
            semanticTokens = true,
          },
        },
        lua_ls = {
          settings = {
            format = {
              enable = false,
            },
            diagnostics = { globals = { "vim" } },
            telemetry = { enable = false },
            hint = { enable = true },
            Lua = {
              workspace = {
                checkThirdParty = false,
              },
              codeLens = {
                enable = true,
              },
              doc = {
                privateName = { "^_" },
              },
              hint = {
                enable = true,
                setType = false,
                paramType = true,
                paramName = "Disable",
                semicolon = "Disable",
                arrayIndex = "Disable",
              },
              completion = {
                callSnippet = "Replace",
              },
            },
          },
        },
        pyright = {},
        templ = {},
        ts_ls = {},
        yamlls = {
          capabilities = {
            textDocument = {
              foldingRange = {
                dynamicRegistration = false,
                lineFoldingOnly = true,
              },
            },
          },
          settings = {
            redhat = { telemetry = { enabled = false } },
            yaml = {
              schemaStore = {
                enable = true,
                url = "https://www.schemastore.org/api/json/catalog.json",
              },
              format = { enabled = false },
              -- enabling this conflicts between Kubernetes resources, kustomization.yaml, and Helmreleases
              validate = false,
              schemas = {
                kubernetes = "*.yaml",
                ["http://json.schemastore.org/github-workflow"] = ".github/workflows/*",
                ["http://json.schemastore.org/github-action"] = ".github/action.{yml,yaml}",
                ["https://raw.githubusercontent.com/microsoft/azure-pipelines-vscode/master/service-schema.json"] = "azure-pipelines*.{yml,yaml}",
                ["https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json#/$defs/tasks"] = "roles/tasks/*.{yml,yaml}",
                ["https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json#/$defs/playbook"] = "*play*.{yml,yaml}",
                ["http://json.schemastore.org/prettierrc"] = ".prettierrc.{yml,yaml}",
                ["http://json.schemastore.org/kustomization"] = "kustomization.{yml,yaml}",
                ["http://json.schemastore.org/chart"] = "Chart.{yml,yaml}",
                ["https://json.schemastore.org/dependabot-v2"] = ".github/dependabot.{yml,yaml}",
                ["https://gitlab.com/gitlab-org/gitlab/-/raw/master/app/assets/javascripts/editor/schema/ci.json"] = "*gitlab-ci*.{yml,yaml}",
                ["https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.1/schema.json"] = "*api*.{yml,yaml}",
                ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "*docker-compose*.{yml,yaml}",
                ["https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json"] = "*flow*.{yml,yaml}",
              },
            },
          },
        },
        jsonls = {},
        clangd = {},
        astro = {},
        tailwindcss = {},
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
    end,
  },

  {
    "alirostami1/dpview",
    config = function()
      require("dpview").setup({
        port = 8421,
        preview_theme = "github",
        auto_start = true,
        auto_open_browser = false,
      })
    end,
  },

  -- troubleshooting
  {
    "folke/trouble.nvim",
    event = "VeryLazy",
    opts = {
      modes = {
        test = {
          mode = "diagnostics",
          preview = {
            type = "split",
            relative = "win",
            position = "right",
            size = 0.3,
          },
        },
      },
    },
    cmd = "Trouble",
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        mode = "n",
        "]t",
        function()
          require("trouble").next({ skip_groups = true, jump = true })
        end,
        desc = "Previous Trouble",
      },
      {
        mode = "n",
        "[t",
        function()
          require("trouble").prev({ skip_groups = true, jump = true })
        end,
        desc = "Next Trouble",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>xQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    event = { "BufWritePost", "BufReadPost", "InsertLeave" },
    opts = {
      linters_by_ft = {
        dockerfile = { "hadolint" },
        go = { "golangcilint" },
        markdown = { "markdownlint-cli2" },
        yaml = { "yamllint" },
      },
    },
    config = function(_, opts)
      local lint = require("lint")
      lint.linters_by_ft = opts.linters_by_ft
      local lint_augroup = vim.api.nvim_create_augroup("linting", { clear = true })
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        group = lint_augroup,
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "theHamsta/nvim-dap-virtual-text",

      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio", -- Required dependency for nvim-dap-ui

      "igorlfs/nvim-dap-view",

      "leoluz/nvim-dap-go",
    },
    ft = { "cpp", "c", "rust", "go" }, -- add filetype after adding config
    keys = {
      {
        "<leader>dr",
        function()
          if vim.fn.filereadable(".vscode/launch.json") == 1 then
            require("dap.ext.vscode").load_launchjs()
          end
          require("dap").continue()
        end,
        desc = "Debug: Start/Continue",
      },
      {
        "<leader>dt",
        function()
          require("dap").terminate()
        end,
        desc = "Debug: Terminate",
      },
      {
        "<leader>di",
        function()
          require("dap").step_into()
        end,
        desc = "Debug: Step Into",
      },
      {
        "<leader>do",
        function()
          require("dap").step_over()
        end,
        desc = "Debug: Step Over",
      },
      {
        "<leader>dO",
        function()
          require("dap").step_out()
        end,
        desc = "Debug: Step Out",
      },
      {
        "<leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Debug: Toggle Breakpoint",
      },
      {
        "<leader>dB",
        function()
          require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end,
        desc = "Debug: Set Breakpoint",
      },
      {
        "<leader>dc",
        function()
          require("dap").clear_breakpoints()
        end,
        desc = "Debug: Set Breakpoint",
      },
      {
        "<leader>dv",
        function()
          require("dap-view").toggle()
        end,
        desc = "Debug: Open DAP View",
      },
      {
        "<leader>dw",
        function()
          vim.cmd("DapViewWatch")
        end,
        desc = "Debug: Add To Watch",
      },
      {
        "<leader>dk",
        function()
          vim.cmd("DapVirtualTextForceRefresh")
        end,
        desc = "Debug: Refresh Virtual Text",
      },
    },
    config = function()
      local dap = require("dap")
      local dapvirt = require("nvim-dap-virtual-text")

      dapvirt.setup()
      dap.listeners.before.event_terminated["dapui_config"] = function()
        require("dap-view").close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        require("dap-view").close()
      end
      dap.listeners.after.event_terminated["dapui_config"] = function()
        vim.cmd("DapVirtualTextForceRefresh")
      end
      dap.listeners.after.event_exited["dapui_config"] = function()
        vim.cmd("DapVirtualTextForceRefresh")
      end

      -- dap.set_log_level("DEBUG")

      -- C/C++/Rust
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = "codelldb",
          args = { "--port", "${port}" },
          detached = function()
            if vim.fn.has("win32") == 1 then
              return false
            else
              return true
            end
          end,
        },
      }
      dap.configurations.cpp = {
        {
          name = "Launch",
          type = "codelldb",
          request = "launch",
          program = function() -- Ask the user what executable wants to debug
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = vim.fn.getcwd(),
          stopOnEntry = true,
          args = function()
            local input = vim.fn.input("Program arguments: ")
            return vim.split(vim.trim(input), "%s+")
          end,
        },
      }
      dap.configurations.c = dap.configurations.cpp
      dap.configurations.rust = dap.configurations.cpp

      -- Go
      require("dap-go").setup({
        delve = {
          detached = vim.fn.has("win32") == 0,
        },
      })
    end,
  },

  -- refactoring
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
    -- This will provide type hinting with LuaLS
    ---@module "conform"
    ---@type conform.setupOpts
    opts = {
      -- Define your formatters
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff" },
        javascript = { "prettierd", "prettier", stop_after_first = true },
        json = { "prettierd", "prettier", stop_after_first = true },
        markdown = { "prettierd", "prettier", stop_after_first = true },
        go = { "gofumpt", "gofmt", stop_after_first = true },
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
    },
    init = function()
      -- If you want the formatexpr, here is the place to set it
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

  -- navigation
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
        -- WARNING CONFLICT: <leader>sW has both normal-mode and visual-mode mappings.
        "<leader>sW",
        function()
          FzfLua.grep_cWORD()
        end,
        desc = "Grep WORD under cursor",
        mode = { "n" },
      },
      {
        -- WARNING CONFLICT: <leader>sW has both normal-mode and visual-mode mappings.
        "<leader>sW",
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

  -- git
  {
    "tpope/vim-fugitive",
    event = "VeryLazy",
    cmd = {
      "Git",
    },
    keys = {
      { mode = "n", "<leader>gg", ":Git<CR>" },
      -- WARNING CONFLICT: <leader>gd is mapped twice in this section.
      { mode = "n", "<leader>gd", ":Gdiff<CR>" },
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
      -- WARNING CONFLICT: <leader>gd is mapped twice in this section.
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

  -- treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "VeryLazy" },
    branch = "main",
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    opts = {
      grammars = {
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
      },
    },
    config = function(_, opts)
      require("nvim-treesitter").install(opts.grammars)
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = { "VeryLazy" },
    init = function()
      vim.g.no_plugin_maps = true
    end,
    opts = {},
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "VeryLazy" },
    opts = { mode = "cursor", max_lines = 3 },
  },
}

require("lazy").setup(plugins, {
  change_detection = {
    notify = false,
  },
})
