return {
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
              -- set this to your notes root(s)
              roots = { vim.fn.expand("~/notes") },
              glob = "*.md",
              rescan_ms = 5000,
            },
            min_keyword_length = 1,
            score_offset = 10,
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

      -- load community VSCode snippets (friendly-snippets)
      vscode_loader.lazy_load()

      -- load your own VSCode-style snippets from: ~/.config/nvim/snippets/
      vscode_loader.load({
        paths = { vim.fn.stdpath("config") .. "/snippets" },
      })
    end,
  },
}
