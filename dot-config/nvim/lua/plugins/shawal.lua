-- All plugins
return {
	"shawal-mbalire/neovim-renderer-plugins",
	ft = { "markdown", "ipynb", "png", "jpg", "jpeg", "gif", "webp" },
	config = function()
		require("renderer-markdown").setup()
		require("renderer-ipynb").setup()
		require("renderer-image").setup()
	end,
}
