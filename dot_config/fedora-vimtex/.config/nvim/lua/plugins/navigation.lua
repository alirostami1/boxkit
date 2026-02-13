return {
	{
		"ibhagwan/fzf-lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			keymap = {
				fzf = {
					["ctrl-q"] = "select-all+accept",
				},
			},
		},
		keys = {
			{
				"<leader>/",
				function()
					FzfLua.live_grep()
				end,
				desc = "Grep",
			},
			{
				"<leader>fb",
				function()
					FzfLua.buffers()
				end,
				desc = "Buffers",
			},
			{
				"<leader>ff",
				function()
					FzfLua.files()
				end,
				desc = "Find Files",
			},
			{
				"<leader>fg",
				function()
					FzfLua.git_files()
				end,
				desc = "Find Git Files",
			},
			{
				"<leader>sw",
				function()
					FzfLua.grep_cword()
				end,
				desc = "Grep word under cursor",
				mode = { "n" },
			},
			{
				"<leader>sW",
				function()
					FzfLua.grep_cWORD()
				end,
				desc = "Grep WORD under cursor",
				mode = { "n" },
			},
			{
				"<leader>sW",
				function()
					FzfLua.grep_visual()
				end,
				desc = "Visual selection or word",
				mode = { "v", "x" },
			},
			{
				"<leader>sk",
				function()
					FzfLua.keymaps()
				end,
				desc = "Keymaps",
			},
			{
				"<leader>sl",
				function()
					FzfLua.loclist()
				end,
				desc = "Location List",
			},
			{
				"<leader>sq",
				function()
					FzfLua.quickfix()
				end,
				desc = "Quickfix List",
			},
			{
				"grd",
				function()
					FzfLua.lsp_definitions()
				end,
				desc = "Goto Definition",
			},
			{
				"grD",
				function()
					FzfLua.lsp_declarations()
				end,
				desc = "Goto Declaration",
			},
			{
				"grr",
				function()
					FzfLua.lsp_references()
				end,
				nowait = true,
				desc = "References",
			},
			{
				"gri",
				function()
					FzfLua.lsp_implementations()
				end,
				desc = "Goto Implementation",
			},
			{
				"grt",
				function()
					FzfLua.lsp_type_definitions()
				end,
				desc = "Goto T[y]pe Definition",
			},
			{
				"gO",
				function()
					FzfLua.lsp_document_symbols()
				end,
				desc = "LSP Document Symbols",
			},
			{
				"go",
				function()
					FzfLua.lsp_workspace_symbols()
				end,
				desc = "LSP Workspace Symbols",
			},
		},
	},
}
