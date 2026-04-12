---@type vim.lsp.Config
return {
  ---@type lspconfig.settings.rust_analyzer
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        allFeatures = true,
      },
      checkOnSave = true,
      check = {
        command = "clippy",
      },
    },
  },
}
