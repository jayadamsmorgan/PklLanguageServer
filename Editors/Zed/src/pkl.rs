use std::fs;
use zed::LanguageServerId;
use zed_extension_api::{self as zed, Result};

struct PklLSExtension {
    cached_binary_path: Option<String>,
}

impl PklLSExtension {
    fn language_server_binary_path(
        &mut self,
        _language_server_id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<String> {
        // if let Some(path) = &self.cached_binary_path {
        //     if fs::metadata(path).map_or(false, |stat| stat.is_file()) {
        //         return Ok(path.clone());
        //     }
        // }

        if let Some(path) = worktree.which("pkl-lsp-server") {
            self.cached_binary_path = Some(path.clone());
            return Ok(path);
        }
        return Err("pkl-lsp-server not found".into());
    }
}

impl zed::Extension for PklLSExtension {
    fn new() -> Self {
        Self {
            cached_binary_path: None,
        }
    }

    fn language_server_command(
        &mut self,
        language_server_id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<zed::Command> {
        Ok(zed::Command {
            command: self.language_server_binary_path(language_server_id, worktree)?,
            args: vec![],
            env: Default::default(),
        })
    }
}

zed::register_extension!(PklLSExtension);

