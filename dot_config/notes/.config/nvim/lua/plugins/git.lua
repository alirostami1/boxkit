return {
	{
		"tpope/vim-fugitive",
		event = "VeryLazy",
		cmd = {
			"Git",
		},
		keys = {
			{ mode = "n", "<leader>gg", ":Git<CR>" },
			{ mode = "n", "<leader>gd", ":Gdiff<CR>" },
			{
				mode = "n",
				"<leader>gc",
				function()
					local commit_message = vim.fn.input("commit message > ")
					vim.cmd('Git commit -m "' .. commit_message .. '"')
				end,
			},
			{ mode = "n", "<leader>gB", ":Git blame<CR>", desc = "Git blame" },
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
}
