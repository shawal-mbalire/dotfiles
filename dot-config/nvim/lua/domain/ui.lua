-- Domain: UI preferences
-- Pure configuration — defines WHAT the editor should look like.

local M = {}

--- Colorscheme preference
M.colorscheme = "catppuccin-mocha"

--- Transparency settings
M.transparency = {
  enabled = true,
  -- UI elements that should have transparent background
  highlights = {
    "Normal",
    "NormalNC",
    "NormalFloat",
    "FloatBorder",
    "SignColumn",
    "EndOfBuffer",
    "LineNr",
    "CursorLineNr",
    "MsgArea",
    "MsgSeparator",
    "Pmenu",
    "PmenuSel",
    "PmenuSbar",
    "PmenuThumb",
    "WinSeparator",
    "StatusLine",
    "StatusLineNC",
    "TabLine",
    "TabLineFill",
    "TabLineSel",
    "VertSplit",
    "FoldColumn",
    "Folded",
    "NonText",
    "SpecialKey",
    "Visual",
    "VisualNOS",
    "WildMenu",
    "DiagnosticSignError",
    "DiagnosticSignWarn",
    "DiagnosticSignInfo",
    "DiagnosticSignHint",
    "DiagnosticVirtualTextError",
    "DiagnosticVirtualTextWarn",
    "DiagnosticVirtualTextInfo",
    "DiagnosticVirtualTextHint",
  },
}

--- Rendering preferences (markdown, images, notebooks)
M.render = {
  markdown = true,
  ipynb = true,
  images = true,
  filetypes = { "markdown", "ipynb", "png", "jpg", "jpeg", "gif", "webp" },
}

return M
