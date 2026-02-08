return {
  {
    "ThePrimeagen/99",
    config = function()
      local _99 = require("99")
      local cwd = vim.uv.cwd()
      local basename = vim.fs.basename(cwd)

      _99.setup({
        model = "anthropic/claude-opus-4-5",
        logger = {
          level = _99.DEBUG,
          path = "/tmp/" .. basename .. ".99.debug",
          print_on_error = true,
        },
        completion = {
          source = "cmp",
          custom_rules = {
            vim.fn.expand("~/.config/opencode/skills/"),
          },
        },
        md_files = {
          "AGENT.md",
        },
        display_errors = true,
      })

      vim.keymap.set("v", "<leader>9v", _99.visual, { desc = "99: Prompt on visual selection" })
      vim.keymap.set({ "n", "v" }, "<leader>9s", _99.stop_all_requests, { desc = "99: Stop all requests" })
    end,
  },
}
