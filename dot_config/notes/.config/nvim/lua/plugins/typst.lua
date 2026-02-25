return {
  {
    "chomosuke/typst-preview.nvim",
    ft = "typst",
    version = "1.*",
    opts = {
      open_cmd = "bash -lc 'GIO_USE_PORTALS=1 gio open \"$1\" 2>/dev/null' _ %s",
    },
  },
}
