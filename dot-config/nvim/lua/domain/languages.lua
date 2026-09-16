-- Domain: Language-specific preferences
-- Pure configuration — defines which languages and their behaviors.

local M = {}

--- Python-specific settings
M.python = {
  venv_selector = true,
  venv_key = ",v",
}

--- MQL (MetaTrader) support
M.mql = {
  filetype = true,
}

--- Languages with LazyVim extras enabled (from lazyvim.json)
M.enabled_extras = {
  "angular",
  "clangd",
  "clojure",
  "dart",
  "docker",
  "git",
  "go",
  "java",
  "json",
  "kotlin",
  "markdown",
  "nushell",
  "python",
  "rust",
  "sql",
  "tailwind",
  "terraform",
  "tex",
  "toml",
  "typescript",
  "yaml",
  "zig",
}

return M
