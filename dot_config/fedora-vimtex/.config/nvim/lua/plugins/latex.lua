return {
	{
		"lervag/vimtex",
		ft = { "tex", "bib" },
		init = function()
			local tmp_root = vim.env.TMPDIR or "/tmp"
			local vimtex_aux_dir = tmp_root .. "/vimtex"

			vim.fn.mkdir(vimtex_aux_dir, "p")

			vim.g.vimtex_view_method = "zathura"
			vim.g.vimtex_compiler_method = "latexmk"
			vim.g.vimtex_compiler_latexmk = {
				options = {
					"-pdf",
					"-interaction=nonstopmode",
					"-synctex=1",
					"-file-line-error",
					"-auxdir=" .. vimtex_aux_dir,
				},
			}
			vim.g.vimtex_quickfix_mode = 0
		end,
	},
}
