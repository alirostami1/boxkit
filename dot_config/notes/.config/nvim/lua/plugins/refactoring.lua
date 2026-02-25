return {
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
        json = { "prettierd", "prettier", stop_after_first = true },
        markdown = { "prettierd", "prettier", stop_after_first = true },
      },
      default_format_opts = {
        lsp_format = "fallback",
      },
      format_on_save = { timeout_ms = 500 },
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
}
