return {
  {
    "ThePrimeagen/99",
    config = function()
      local _99 = require("99")
      local cwd = vim.uv.cwd()
      local basename = vim.fs.basename(cwd)

      _99.setup({
        model = "anthropic/claude-opus-4-5", -- Claude Opus 4.5 (latest) via Anthropic
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
        display_errors = true, -- Show full error messages
      })

      -- Keymaps
      vim.keymap.set("n", "<leader>9f", function()
        _99.fill_in_function()
      end, { desc = "Fill in function with AI" })

      vim.keymap.set("v", "<leader>9v", function()
        _99.visual()
      end, { desc = "AI operate on visual selection" })

      vim.keymap.set("v", "<leader>9p", function()
        _99.visual_prompt()
      end, { desc = "AI operate on visual selection with prompt" })

      vim.keymap.set("v", "<leader>9s", function()
        _99.stop_all_requests()
      end, { desc = "Stop AI requests" })
    end,
  },
}
