---@type vim.lsp.Config
return {
  ---@type lspconfig.settings.lua_ls
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
        setType = true,
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
}
