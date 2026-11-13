-- Open the file tree on start, like Zed; skip when nvim is git's editor.
-- VeryLazy: this file loads before plugins when nvim opens a file.
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    local ft = vim.bo.filetype
    if ft == "gitcommit" or ft == "gitrebase" or #Snacks.picker.get({ source = "explorer" }) > 0 then
      return
    end
    Snacks.explorer({ enter = false })
  end,
})
