local state_home = vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")

return dofile(state_home .. "/omarchy/current/theme/neovim.lua")
