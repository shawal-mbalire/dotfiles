-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
-- Ensure autoread is on
vim.o.autoread = true

-- Trigger checktime when gaining focus or stopping typing
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  pattern = "*",
  callback = function()
    if vim.fn.mode() ~= "c" then
      vim.cmd("checktime")
    end
  end,
})
