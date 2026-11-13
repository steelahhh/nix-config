return {
  -- LSPs are installed by nix (see vim.nix)
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        elixirls = { enabled = false },
        expert = {},
        nil_ls = { enabled = false },
        nixd = {},
      },
    },
  },
}
