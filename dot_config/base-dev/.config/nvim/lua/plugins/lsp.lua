return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile", "BufWritePre" },
	dependencies = {
		"saghen/blink.cmp",
	},
	keys = {
		{ mode = { "n" }, "<leader>lr", "<cmd>LspRestart<CR>" },
		{ mode = { "n" }, "<leader>li", "<cmd>LspInfo<CR>" },
		{ mode = "n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>" },
		{ mode = "n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>" },
		{ mode = "n", "<leader>d", "<cmd>lua vim.diagnostic.open_float()<CR>" },
	},
	opts = {
		capabilities = {
			workspace = {
				fileOperations = {
					didRename = true,
					willRename = true,
				},
			},
		},
		servers = {
			bashls = {},
			gopls = {
				settings = {
					gofumpt = true,
					codelenses = {
						gc_details = false,
						generate = true,
						regenerate_cgo = true,
						run_govulncheck = true,
						test = true,
						tidy = true,
						upgrade_dependency = true,
						vendor = true,
					},
					hints = {
						assignVariableTypes = true,
						compositeLiteralFields = true,
						compositeLiteralTypes = true,
						constantValues = true,
						functionTypeParameters = true,
						parameterNames = true,
						rangeVariableTypes = true,
					},
					analyses = {
						fieldalignment = true,
						nilness = true,
						unusedparams = true,
						unusedwrite = true,
						useany = true,
					},
					usePlaceholders = true,
					completeUnimported = true,
					staticcheck = true,
					directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
					semanticTokens = true,
				},
			},
			lua_ls = {
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
							setType = false,
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
			},
			pyright = {},
			templ = {},
			ts_ls = {},
			yamlls = {
				capabilities = {
					textDocument = {
						foldingRange = {
							dynamicRegistration = false,
							lineFoldingOnly = true,
						},
					},
				},
				settings = {
					redhat = { telemetry = { enabled = false } },
					yaml = {
						schemaStore = {
							enable = true,
							url = "https://www.schemastore.org/api/json/catalog.json",
						},
						format = { enabled = false },
						-- enabling this conflicts between Kubernetes resources, kustomization.yaml, and Helmreleases
						validate = false,
						schemas = {
							kubernetes = "*.yaml",
							["http://json.schemastore.org/github-workflow"] = ".github/workflows/*",
							["http://json.schemastore.org/github-action"] = ".github/action.{yml,yaml}",
							["https://raw.githubusercontent.com/microsoft/azure-pipelines-vscode/master/service-schema.json"] = "azure-pipelines*.{yml,yaml}",
							["https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json#/$defs/tasks"] = "roles/tasks/*.{yml,yaml}",
							["https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json#/$defs/playbook"] = "*play*.{yml,yaml}",
							["http://json.schemastore.org/prettierrc"] = ".prettierrc.{yml,yaml}",
							["http://json.schemastore.org/kustomization"] = "kustomization.{yml,yaml}",
							["http://json.schemastore.org/chart"] = "Chart.{yml,yaml}",
							["https://json.schemastore.org/dependabot-v2"] = ".github/dependabot.{yml,yaml}",
							["https://gitlab.com/gitlab-org/gitlab/-/raw/master/app/assets/javascripts/editor/schema/ci.json"] = "*gitlab-ci*.{yml,yaml}",
							["https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.1/schema.json"] = "*api*.{yml,yaml}",
							["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "*docker-compose*.{yml,yaml}",
							["https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json"] = "*flow*.{yml,yaml}",
						},
					},
				},
			},
			jsonls = {},
			clangd = {},
			astro = {},
			tailwindcss = {},
		},
	},
	config = function(_, opts)
		vim.diagnostic.config({
			virtual_text = true,
			update_in_insert = false,
			underline = true,
		})

		local capabilities = vim.lsp.protocol.make_client_capabilities()
		capabilities = vim.tbl_deep_extend("force", capabilities, require("blink.cmp").get_lsp_capabilities({}, false))
		for server, server_opts in pairs(opts.servers) do
			server_opts.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server_opts.capabilities or {})
			vim.lsp.config(server, server_opts)
			vim.lsp.enable(server)
		end

		-- Use LspAttach autocommand to only map the following keys
		-- after the language server attaches to the current buffer
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				-- Buffer local mappings.
				-- See `:help vim.lsp.*` for documentation on any of the below functions
				local keymap_options = { buffer = ev.buf }
				vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, keymap_options)
			end,
		})
	end,
}
