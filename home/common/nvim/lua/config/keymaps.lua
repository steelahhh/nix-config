-- Ported from home/common/idea.vimrc and the old Zed keymap
local map = vim.keymap.set

-- Zed
map("n", "<leader>f", function() Snacks.picker.files() end, { desc = "Find Files" })
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>lf", function() LazyVim.format({ force = true }) end, { desc = "Format" })
map({ "n", "t" }, "<D-j>", function() Snacks.terminal() end, { desc = "Toggle Terminal" })

-- IdeaVim
map("n", "<leader>?", function() Snacks.picker.commands() end, { desc = "Commands" })
map("n", "<leader>a", function() Snacks.picker.grep() end, { desc = "Find in Path" })
map("n", "<leader>h", "<cmd>nohlsearch<cr>", { desc = "Clear Search Highlight" })
map("n", "<leader>n", function()
  vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true })
end, { desc = "Next Error" })
map("n", "gi", function() Snacks.picker.lsp_implementations() end, { desc = "Goto Implementation" })
map("n", "gs", function() vim.lsp.buf.typehierarchy("supertypes") end, { desc = "Goto Super" })
map({ "n", "i" }, "<C-p>", vim.lsp.buf.signature_help, { desc = "Parameter Info" })

map("n", "<leader>rr", vim.lsp.buf.rename, { desc = "Rename" })
map("n", "<leader>ro", LazyVim.lsp.action["source.organizeImports"], { desc = "Organize Imports" })
map({ "n", "x" }, "<leader>rev", "<leader>rx", { remap = true, desc = "Extract Variable" })
map({ "n", "x" }, "<leader>rem", "<leader>rf", { remap = true, desc = "Extract Method" })
map("n", "<leader>gr", function() require("gitsigns").reset_hunk() end, { desc = "Rollback Changed Lines" })

map("n", "<leader>p", "v$<Left>p", { desc = "Paste Over Rest of Line" })
map("x", "p", "P") -- don't overwrite the register when pasting over a selection
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
