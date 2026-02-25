return {
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

    -- Use LspAttach autocommand to only map the following keys
    -- after the language server attaches to the current buffer
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", {}),
      callback = function(ev)
        -- Buffer local mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local keymap_options = { buffer = ev.buf }
        vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, keymap_options)
      end,
    })
  end,
}
