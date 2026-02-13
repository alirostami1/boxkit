return {
	{
		"saghen/blink.cmp",
		event = "InsertEnter",
		version = "1.*",
		dependencies = { "rafamadriz/friendly-snippets" },
		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			keymap = { preset = "default" },
			appearance = {},
			snippets = {
				preset = "default",
			},
			completion = {
				documentation = {
					auto_show = true,
					auto_show_delay_ms = 250,
					treesitter_highlighting = true,
					window = { border = "rounded" },
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
					border = "rounded",
					draw = {
						columns = { { "label", "label_description", gap = 1 }, { "kind_icon" } },
					},
				},
			},
			signature = {
				enabled = false,
			},
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
			fuzzy = { implementation = "prefer_rust_with_warning" },
		},
	},
}
