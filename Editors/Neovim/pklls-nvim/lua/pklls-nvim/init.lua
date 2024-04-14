local M = {}

function M.setup(config)
	local lspConfigExists, configs = pcall(require, "lspconfig.configs")
	if not lspConfigExists then
		print("[pklls-nvim] 'lspconfig' not found")
		print("[pklls-nvim] Please install 'neovim/nvim-lspconfig'")
		return
	end
	local lspconfig = require("lspconfig")
	configs.pklls = {
		default_config = {
			cmd = {
				"pkl-lsp-server",
			},
			filetypes = { "pkl" },
			root_dir = lspconfig.util.root_pattern(".git", "PklProject", ".pkl", "."),
			settings = {},
		},
	}
	lspconfig.pklls.setup(config)
end

return M
