-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Theme toggle: dark (aether) <-> light (rose-pine dawn)
vim.g.current_theme_dark = true -- Start with dark theme

local function apply_transparency()
  vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
  vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
  vim.api.nvim_set_hl(0, "Pmenu", { bg = "none" })
  vim.api.nvim_set_hl(0, "Terminal", { bg = "none" })
  vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
  vim.api.nvim_set_hl(0, "FoldColumn", { bg = "none" })
  vim.api.nvim_set_hl(0, "Folded", { bg = "none" })
  vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
  vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
  vim.api.nvim_set_hl(0, "WhichKeyFloat", { bg = "none" })
  vim.api.nvim_set_hl(0, "TelescopeBorder", { bg = "none" })
  vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = "none" })
  vim.api.nvim_set_hl(0, "TelescopePromptBorder", { bg = "none" })
  vim.api.nvim_set_hl(0, "TelescopePromptTitle", { bg = "none" })
  vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "none" })
  vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "none" })
  vim.api.nvim_set_hl(0, "NeoTreeVertSplit", { bg = "none" })
  vim.api.nvim_set_hl(0, "NeoTreeWinSeparator", { bg = "none" })
  vim.api.nvim_set_hl(0, "NeoTreeEndOfBuffer", { bg = "none" })
  vim.api.nvim_set_hl(0, "NvimTreeNormal", { bg = "none" })
  vim.api.nvim_set_hl(0, "NvimTreeVertSplit", { bg = "none" })
  vim.api.nvim_set_hl(0, "NvimTreeEndOfBuffer", { bg = "none" })
  vim.api.nvim_set_hl(0, "NotifyINFOBody", { bg = "none" })
  vim.api.nvim_set_hl(0, "NotifyERRORBody", { bg = "none" })
  vim.api.nvim_set_hl(0, "NotifyWARNBody", { bg = "none" })
  vim.api.nvim_set_hl(0, "NotifyTRACEBody", { bg = "none" })
  vim.api.nvim_set_hl(0, "NotifyDEBUGBody", { bg = "none" })
  vim.api.nvim_set_hl(0, "NotifyINFOTitle", { bg = "none" })
  vim.api.nvim_set_hl(0, "NotifyERRORTitle", { bg = "none" })
  vim.api.nvim_set_hl(0, "NotifyWARNTitle", { bg = "none" })
  vim.api.nvim_set_hl(0, "NotifyTRACETitle", { bg = "none" })
  vim.api.nvim_set_hl(0, "NotifyDEBUGTitle", { bg = "none" })
  vim.api.nvim_set_hl(0, "NotifyINFOBorder", { bg = "none" })
  vim.api.nvim_set_hl(0, "NotifyERRORBorder", { bg = "none" })
  vim.api.nvim_set_hl(0, "NotifyWARNBorder", { bg = "none" })
  vim.api.nvim_set_hl(0, "NotifyTRACEBorder", { bg = "none" })
  vim.api.nvim_set_hl(0, "NotifyDEBUGBorder", { bg = "none" })
end

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
    vim.defer_fn(apply_transparency, 10)
    vim.notify("Dark theme: aether", vim.log.levels.INFO)
  end
end

vim.keymap.set("n", "<leader>tt", toggle_theme, { desc = "Toggle dark/light theme" })
