# Starting PklLanguageServer in Neovim

## pkl-neovim

This language server also works great along side with Apple's [pkl-neovim][uri-pkl-neovim] plugin which provides tree-sitter highlighting and indentation.

## Installation

1. Install [PklLanguageServer][uri-pkl-ls] by copying it to `/usr/bin` or `/usr/local/bin` or add it to your PATH variable.

2. Install pklls-nvim plugin:

   - [packer.nvim][uri-packer]:

     ```lua
     use({
       "jayadamsmorgan/PklLanguageServer",
       requires = {
         "neovim/nvim-lspconfig",
       },
       run = "mv Editors/Neovim/pklls-nvim/* .",
     })
     ```

     Then add language server setup like any other server config:

     ```lua
     local capabilities = require("cmp_nvim_lsp").default_capabilities() -- if you are using nvim_cmp for completion
     require("pklls-nvim.init").setup({
       capabilities = capabilities,
       -- on_attach = your_on_attach, -- change or remove this
       -- cmd = custom_path_to_pkl_lsp_server, -- change or remove this
     })
     ```

   - [lazy.nvim][uri-lazy]:

     ```lua
     {
       "jayadamsmorgan/PklLanguageServer",
       build = "mv Editors/Neovim/pklls-nvim/* .",
       config = function()
         local capabilities = require("cmp_nvim_lsp").default_capabilities() -- if you are using nvim_cmp for completion
         require("pklls-nvim.init").setup({
           capabilities = capabilities, -- change or remove this
           -- on_attach = custom_on_attach -- change or remove this
           -- cmd = custom_path_to_pkl_lsp_server
         })
       end,
       dependencies = {
         "neovim/nvim-lspconfig",
       },
     }
     ```

[uri-lazy]: https://github.com/folke/lazy.nvim
[uri-packer]: https://github.com/wbthomason/packer.nvim
[uri-pkl-ls]: https://github.com/jayadamsmorgan/PklLanguageServer
[uri-pkl-neovim]: https://github.com/apple/pkl-neovim
