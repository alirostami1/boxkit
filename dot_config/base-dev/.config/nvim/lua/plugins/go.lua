return {
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
}
