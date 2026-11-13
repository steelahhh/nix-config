return {
  -- vim-surround keys, like `set surround` in idea.vimrc
  {
    "nvim-mini/mini.surround",
    opts = {
      mappings = {
        add = "ys",
        delete = "ds",
        replace = "cs",
        find = "",
        find_left = "",
        highlight = "",
        update_n_lines = "",
      },
    },
    keys = {
      { "yss", "ys_", remap = true, desc = "Surround Line" },
      { "S", [[:<C-u>lua MiniSurround.add('visual')<cr>]], mode = "x", silent = true, desc = "Surround Selection" },
    },
  },
  {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    event = "VeryLazy",
    config = function()
      local mc = require("multicursor-nvim")
      mc.setup()
      vim.keymap.set({ "n", "x" }, "<C-n>", function() mc.matchAddCursor(1) end, { desc = "Add Cursor at Next Match" })
      vim.keymap.set({ "n", "x" }, "<C-S-n>", function() mc.matchSkipCursor(1) end, { desc = "Skip Match" })
      mc.addKeymapLayer(function(layerSet)
        layerSet("n", "<esc>", mc.clearCursors)
      end)
    end,
  },
}
