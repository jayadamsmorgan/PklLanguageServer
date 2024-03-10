# Starting PklLanguageServer in Neovim

## pkl-neovim

This language server also works great along side with Apple's [pkl-neovim][uri-pkl-neovim] plugin which provides tree-sitter highlighting and indentation.

**Note:**
As of today, highlighting is broken on Apple's repo when using latest tree-sitter.
I have sent a PR to fix it and for now you can use [my fork][uri-pkl-neovim-fork] instead until PR is accepted.

## Installation

1. Install [PklLanguageServer][uri-pkl-ls]

1. Add a hook to let Neovim recognize Pkl filetype:

**Note:** If you have [pkl-neovim][uri-pkl-neovim] installed you can skip this step.

```lua
vim.cmd([[autocmd BufRead,BufNewFile PklProject,*.pkl,*.pcf setfiletype pkl]])
```

3. Install [nvim-lspconfig][uri-lspconfig] and add custom server to configs:

```lua
local configs = require("lspconfig.configs")

configs.pklls = {
  default_config = {
    cmd = {
      "pkl-lsp-server", -- OR path to where you installed `pkl-lsp-server`
      -- You can also spawn it with some options:
      -- "-l", "debug", "-f", "pkl-lsp.log",
    },
    filetypes = { "pkl" },
    root_dir = require("lspconfig/util").root_pattern(".git", "PklProject", ".pkl"),
    settings = {},
  },
}
```

4. Now you can configure the server itself as any other LSP:

```lua
local lspconfig = require("lspconfig")

lspconfig["pklls"].setup({
  on_attach = on_attach, -- Change to your `on_attach`
  capabilities = capabilities, -- Change to your `capabilities`
})
```

[uri-pkl-ls]: https://github.com/jayadamsmorgan/PklLanguageServer
[uri-pkl-neovim]: https://github.com/apple/pkl-neovim
[uri-pkl-neovim-fork]: https://github.com/jayadamsmorgan/pkl-neovim
[uri-lspconfig]: https://github.com/neovim/nvim-lspconfig
