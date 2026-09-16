-- lazy.nvim bootstrap + plugin specification
--
-- This is the lazy.nvim entry point. It loads:
--   1. LazyVim base config (colorscheme, defaults)
--   2. All files in lua/plugins/ (auto-discovered category files)
--
-- Plugin files in lua/plugins/ call adapters, which read from domain.
-- This keeps the wiring thin and the domain pure.

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

local domain = require("domain.ui")

require("lazy").setup({
	spec = {
		-- LazyVim base + language extras
		{ "LazyVim/LazyVim", import = "lazyvim.plugins", colorscheme = domain.colorscheme },

		-- Auto-discovered plugin specs (ui.lua, editor.lua, navigation.lua, lang.lua, tools.lua)
		-- Each file calls adapters which read from domain modules.
		{ import = "plugins" },
	},
	defaults = {
		lazy = false,
		version = false,
	},
	install = { colorscheme = { domain.colorscheme, "catppuccin" } },
	checker = {
		enabled = true,
		notify = false,
	},
	performance = {
		rtp = {
			disabled_plugins = {
				"gzip",
				"matchit",
				"matchparen",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
})
