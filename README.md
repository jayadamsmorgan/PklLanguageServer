<div align="center">

[![Discord][discord badge]][discord]

# PklLanguageServer

Language server for Apple Pkl language written in Swift.

</div>

## Overview
This language server is still in a **very early development stage**.

The goal of this project is to make a fully functional Language Server for Pkl language and have lots of fun.

## Contributing
I would really love to make it a community driven project, so don't hesitate to contribute or help in any way possible.

The [Discord Server][discord] is there for any question, help, advice or just casual chatting.

Also check out [Unofficial Pkl Community Discord Server][community discord], lots of great people there discussing Pkl. They also have a channel about LSPs!

And don't forget to check [Code of Conduct](CODE_OF_CONDUCT.md).

## Installing and running from source:

Clone repository and build the project:
```
git clone https://github.com/jayadamsmorgan/PklLanguageServer
cd PklLanguageServer
swift build -c release
```

Install (optional):
```
sudo cp .build/release/pkl-lsp-server /usr/bin/.
```

Now you can run the server with:
```
pkl-lsp-server
```

Check help for more options:
```
pkl-lsp-server -h
```

## Honorable mentions

Huge shoutout to Mattie, creator of [LanguageServerProtocol][lsplib] and [SwiftTreeSitter][tslib] libraries.

This project could not have been possible without his great work and huge help. Check out his awesome [blog][matts blog].



[discord]: https://discord.gg/GTe5JvcT
[community discord]: https://discord.gg/3PufS9Jn
[discord badge]: https://img.shields.io/badge/Discord-purple?logo=Discord&label=Chat&color=%235A64EC

[lsplib]: https://github.com/ChimeHQ/LanguageServerProtocol
[tslib]: https://github.com/ChimeHQ/SwiftTreeSitter
[matts blog]: https://www.massicotte.org/
