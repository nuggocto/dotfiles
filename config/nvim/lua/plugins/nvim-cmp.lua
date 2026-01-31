-- Use nvim-cmp instead of blink.cmp
-- This works with vim.g.lazyvim_cmp = "nvim-cmp" set in options.lua
return {
  -- Import LazyVim's nvim-cmp extra to get proper configuration
  { import = "lazyvim.plugins.extras.coding.nvim-cmp" },
}
