import * as path from "path";
import * as vscode from "vscode";
import {
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
  TransportKind,
} from "vscode-languageclient/node";

const serverOptions: ServerOptions = {
  run: {
    command: "pkl-lsp-server",
    args: ["-l", "info", "-f", "pkl-lsp-server.log"],
  },
  debug: {
    command: "pkl-lsp-server",
    args: ["-l", "debug", "-f", "pkl-lsp-server.log"],
  },
};

const clientOptions: LanguageClientOptions = {
  documentSelector: [{ scheme: "file", language: "pkl" }],
  synchronize: {
    fileEvents: vscode.workspace.createFileSystemWatcher("**/.pkl"),
  },
};

const client = new LanguageClient(
  "pklLanguageServer",
  "PKL Language Server",
  serverOptions,
  clientOptions,
);

export function activate(context: vscode.ExtensionContext) {
  client.start();
}

export function deactivate(): Thenable<void> | undefined {
  if (!client) {
    return undefined;
  }
  return client.stop();
}
