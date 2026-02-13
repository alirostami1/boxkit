return {
	{
		"folke/trouble.nvim",
		event = "VeryLazy",
		opts = {
			modes = {
				test = {
					mode = "diagnostics",
					preview = {
						type = "split",
						relative = "win",
						position = "right",
						size = 0.3,
					},
				},
			},
		},
		cmd = "Trouble",
		keys = {
			{
				"<leader>xx",
				"<cmd>Trouble diagnostics toggle<cr>",
				desc = "Diagnostics (Trouble)",
			},
			{
				"<leader>xX",
				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				desc = "Buffer Diagnostics (Trouble)",
			},
			{
				mode = "n",
				"]t",
				function()
					require("trouble").next({ skip_groups = true, jump = true })
				end,
				desc = "Previous Trouble",
			},
			{
				mode = "n",
				"[t",
				function()
					require("trouble").prev({ skip_groups = true, jump = true })
				end,
				desc = "Next Trouble",
			},
			{
				"<leader>cs",
				"<cmd>Trouble symbols toggle focus=false<cr>",
				desc = "Symbols (Trouble)",
			},
			{
				"<leader>cl",
				"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
				desc = "LSP Definitions / references / ... (Trouble)",
			},
			{
				"<leader>xL",
				"<cmd>Trouble loclist toggle<cr>",
				desc = "Location List (Trouble)",
			},
			{
				"<leader>xQ",
				"<cmd>Trouble qflist toggle<cr>",
				desc = "Quickfix List (Trouble)",
			},
		},
	},
	{
		"mfussenegger/nvim-lint",
		event = { "BufWritePost", "BufReadPost", "InsertLeave" },
		opts = {
			linters_by_ft = {
				dockerfile = { "hadolint" },
				go = { "golangcilint" },
				markdown = { "markdownlint-cli2" },
				yaml = { "yamllint" },
			},
		},
		config = function(_, opts)
			local lint = require("lint")
			lint.linters_by_ft = opts.linters_by_ft
			local lint_augroup = vim.api.nvim_create_augroup("linting", { clear = true })
			vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function()
					lint.try_lint()
				end,
			})
		end,
	},
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"theHamsta/nvim-dap-virtual-text",

			"rcarriga/nvim-dap-ui",
			"nvim-neotest/nvim-nio", -- Required dependency for nvim-dap-ui

			"igorlfs/nvim-dap-view",

			"leoluz/nvim-dap-go",
		},
		ft = { "cpp", "c", "rust", "go" }, -- add filetype after adding config
		keys = {
			{
				"<leader>dr",
				function()
					if vim.fn.filereadable(".vscode/launch.json") then
						require("dap.ext.vscode").load_launchjs()
					end
					require("dap").continue()
				end,
				desc = "Debug: Start/Continue",
			},
			{
				"<leader>dt",
				function()
					require("dap").terminate()
				end,
				desc = "Debug: Terminate",
			},
			{
				"<leader>di",
				function()
					require("dap").step_into()
				end,
				desc = "Debug: Step Into",
			},
			{
				"<leader>do",
				function()
					require("dap").step_over()
				end,
				desc = "Debug: Step Over",
			},
			{
				"<leader>dO",
				function()
					require("dap").step_out()
				end,
				desc = "Debug: Step Out",
			},
			{
				"<leader>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "Debug: Toggle Breakpoint",
			},
			{
				"<leader>dB",
				function()
					require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
				end,
				desc = "Debug: Set Breakpoint",
			},
			{
				"<leader>dc",
				function()
					require("dap").clear_breakpoints()
				end,
				desc = "Debug: Set Breakpoint",
			},
			{
				"<leader>dv",
				function()
					require("dap-view").toggle()
				end,
				desc = "Debug: Open DAP View",
			},
			{
				"<leader>dw",
				function()
					vim.cmd("DapViewWatch")
				end,
				desc = "Debug: Add To Watch",
			},
			{
				"<leader>dk",
				function()
					vim.cmd("DapVirtualTextForceRefresh")
				end,
				desc = "Debug: Refresh Virtual Text",
			},
		},
		config = function()
			local dap = require("dap")
			local dapvirt = require("nvim-dap-virtual-text")

			dapvirt.setup()
			dap.listeners.before.event_terminated["dapui_config"] = function()
				require("dap-view").close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				require("dap-view").close()
			end
			dap.listeners.after.event_terminated["dapui_config"] = function()
				vim.cmd("DapVirtualTextForceRefresh")
			end
			dap.listeners.after.event_exited["dapui_config"] = function()
				vim.cmd("DapVirtualTextForceRefresh")
			end

			-- dap.set_log_level("DEBUG")

			-- C/C++/Rust
			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",
				executable = {
					command = "codelldb",
					args = { "--port", "${port}" },
					detached = function()
						if vim.fn.has("win32") == 1 then
							return false
						else
							return true
						end
					end,
				},
			}
			dap.configurations.cpp = {
				{
					name = "Launch",
					type = "codelldb",
					request = "launch",
					program = function() -- Ask the user what executable wants to debug
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
					end,
					cwd = vim.fn.getcwd(),
					stopOnEntry = true,
					args = function()
						local input = vim.fn.input("Program arguments: ")
						return vim.split(vim.trim(input), "%s+")
					end,
				},
			}
			dap.configurations.c = dap.configurations.cpp
			dap.configurations.rust = dap.configurations.cpp

			-- Go
			require("dap-go").setup({
				delve = {
					detached = vim.fn.has("win32") == 0,
				},
			})
		end,
	},
}
