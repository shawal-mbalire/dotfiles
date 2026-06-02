-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
vim.filetype.add({
  extension = {
    ino = "cpp",
  },
})

-- Trigger checktime when gaining focus or stopping typing to sync with external changes
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = vim.api.nvim_create_augroup("AutoCheckTime", { clear = true }),
  callback = function()
    if vim.fn.getcmdwintype() == "" then
      vim.cmd("checktime")
    end
  end,
})

-- Force-reload when a file is changed on disk (discard local unsaved changes)
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  callback = function()
    -- Only run when not in a command-line window
    if vim.fn.getcmdwintype() == "" then
      -- Use silent! edit! to reload the file from disk and discard local changes
      pcall(vim.cmd, "silent! edit!")
      vim.notify("File changed on disk. Buffer force-reloaded.", vim.log.levels.INFO)
    end
  end,
})

-- Autosave modified file buffers on focus change (like VSCode)
vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave" }, {
  group = vim.api.nvim_create_augroup("AutoSave", { clear = true }),
  callback = function()
    -- Don't run while in a command-line window
    if vim.fn.getcmdwintype() == "" then
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_get_option(bufnr, "modified")
           and vim.api.nvim_buf_get_option(bufnr, "buflisted")
           and vim.api.nvim_buf_get_option(bufnr, "modifiable")
           and vim.api.nvim_buf_get_option(bufnr, "buftype") == ""
           and vim.api.nvim_buf_get_name(bufnr) ~= "" then
          pcall(vim.api.nvim_buf_call, bufnr, function()
            vim.cmd("silent! write")
          end)
        end
      end
    end
  end,
})
