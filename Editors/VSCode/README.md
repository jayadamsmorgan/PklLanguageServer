# Starting PklLanguageServer in VSCode

## pkl-vscode

This language server extension works great along side with Apple's [pkl-vscode][uri-pkl-vscode] extension which provides tree-sitter highlighting and indenting.

## Installation

1. Install [PklLanguageServer][uri-pkl-ls]

2. Download extension from [latest release][uri-releases]

- Or build it from source ([npm][uri-npm] and [vsce][uri-vsce] are required):

```bash
git clone https://github.com/jayadamsmorgan/PklLanguageServer
cd PklLanguageServer/Editors/VSCode
npm install
npx vsce package
```

3. Install this extension:

```bash
code --install-extension pkl-lsp-vscode-0.1.0.vsix
```

[uri-npm]: https://www.npmjs.com/package/npm
[uri-vsce]: https://github.com/microsoft/vscode-vsce
[uri-releases]: https://github.com/jayadamsmorgan/PklLanguageServer/releases
[uri-pkl-ls]: https://github.com/jayadamsmorgan/PklLanguageServer/blob/master/README.md
[uri-pkl-vscode]: https://github.com/apple/pkl-vscode
