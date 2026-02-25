return {
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
}
