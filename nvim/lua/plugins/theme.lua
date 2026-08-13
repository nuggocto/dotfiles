local config_home = vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. "/.config")

return dofile(config_home .. "/omarchy/current/theme/neovim.lua")
