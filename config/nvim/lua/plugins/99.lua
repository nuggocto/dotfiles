return {
  {
    "ThePrimeagen/99",
    dependencies = {
      { "saghen/blink.compat", version = "2.*", opts = {} },
    },
    config = function()
      local _99 = require("99")
      local worker = _99.Extensions.Worker
      local cwd = vim.uv.cwd()
      local basename = vim.fs.basename(cwd)

      _99.setup({
        model = "openai/gpt-5.3-codex",
        tmp_dir = "./tmp",
        logger = {
          level = _99.DEBUG,
          path = "/tmp/" .. basename .. ".99.debug",
          print_on_error = true,
        },
        completion = {
          source = "blink",
          custom_rules = {
            vim.fn.expand("~/.config/opencode/skills/"),
          },
          files = {},
        },
        md_files = {
          "AGENT.md",
          "AGENTS.md",
        },
        display_errors = true,
      })

      vim.keymap.set("v", "<leader>9v", _99.visual, { desc = "99: Prompt on visual selection" })
      vim.keymap.set("n", "<leader>9ss", _99.search, { desc = "99: Search" })
      vim.keymap.set({ "n", "v" }, "<leader>9x", _99.stop_all_requests, { desc = "99: Stop all requests" })

      vim.keymap.set("n", "<leader>9wd", worker.set_work, { desc = "99: Set work item" })
      vim.keymap.set("n", "<leader>9wg", function()
        print(worker.current_work_item or "No current work item")
      end, { desc = "99: Show work item" })
      vim.keymap.set("n", "<leader>9ww", worker.work, { desc = "99: Run work search" })
      vim.keymap.set("n", "<leader>9wr", worker.last_search_results, { desc = "99: Last work results" })
    end,
  },
  {
    "saghen/blink.cmp",
    optional = true,
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      opts.sources.compat = opts.sources.compat or {}
      if not vim.tbl_contains(opts.sources.compat, "99") then
        table.insert(opts.sources.compat, "99")
      end
    end,
  },
}
