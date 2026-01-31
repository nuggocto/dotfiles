-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Theme toggle: dark (aether) <-> light (rose-pine dawn)
vim.g.current_theme_dark = true -- Start with dark theme

local transparency = require("config.transparency")

local function toggle_theme()
  if vim.g.current_theme_dark then
    -- Switch to light theme (rose-pine dawn)
    vim.o.background = "light"
    vim.cmd.colorscheme("rose-pine")
    vim.g.current_theme_dark = false
    vim.notify("Light theme: rose-pine dawn", vim.log.levels.INFO)
  else
    -- Switch to dark theme (aether)
    vim.o.background = "dark"
    vim.cmd.colorscheme("aether")
    vim.g.current_theme_dark = true
    -- Re-apply transparency for dark theme
    vim.defer_fn(transparency.apply, 10)
    vim.notify("Dark theme: aether", vim.log.levels.INFO)
  end
end

vim.keymap.set("n", "<leader>tt", toggle_theme, { desc = "Toggle dark/light theme" })
