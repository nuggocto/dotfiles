return {
  {
    "ThePrimeagen/99",
    dependencies = {
      { "saghen/blink.compat", version = "2.*", opts = {} },
    },
    config = function()
      local _99 = require("99")
      local worker = _99.Extensions.Worker
      local utils = require("99.utils")
      local cwd = vim.uv.cwd()
      local basename = vim.fs.basename(cwd)
      local tmp_dir = "./tmp"
      local picker

      vim.fn.mkdir(vim.fn.expand(tmp_dir), "p")

      do
        local has_telescope, telescope = pcall(require, "99.extensions.telescope")
        if has_telescope then
          picker = telescope
        else
          local has_fzf_lua, fzf_lua = pcall(require, "99.extensions.fzf_lua")
          if has_fzf_lua then
            picker = fzf_lua
          end
        end
      end

      local function get_current_work_item()
        local current_work_item = worker.current_work_item
        if current_work_item and current_work_item ~= "" then
          return current_work_item
        end

        local work_item_path = utils.named_tmp_file(_99.__get_state():tmp_dir(), "work-item")
        local work_item_file = io.open(work_item_path, "r")
        if not work_item_file then
          return nil
        end

        local work_item = work_item_file:read("*a")
        work_item_file:close()

        if not work_item or work_item == "" then
          return nil
        end

        worker.current_work_item = work_item
        return work_item
      end

      local function open_last_work_results()
        local request_id = worker.last_work_search
        if not request_id then
          vim.notify("99: No work search results yet", vim.log.levels.WARN)
          return
        end

        local requests = _99.__get_state():requests()
        for i = #requests, 1, -1 do
          local request = requests[i]
          if request.xid == request_id then
            _99.open_qfix_for_request(request)
            return
          end
        end

        vim.notify("99: Could not find last work search request", vim.log.levels.WARN)
      end

      _99.setup({
        provider = _99.Providers.OpenCodeProvider,
        model = "openai/gpt-5.3-codex",
        tmp_dir = tmp_dir,
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
      vim.keymap.set("n", "<leader>9s", _99.search, { desc = "99: Search" })
      vim.keymap.set("n", "<leader>9ss", _99.search, { desc = "99: Search" })
      vim.keymap.set({ "n", "v" }, "<leader>9x", _99.stop_all_requests, { desc = "99: Stop all requests" })

      if picker then
        vim.keymap.set("n", "<leader>9m", picker.select_model, { desc = "99: Select model" })
        vim.keymap.set("n", "<leader>9p", picker.select_provider, { desc = "99: Select provider" })
      end

      vim.keymap.set("n", "<leader>9wd", worker.set_work, { desc = "99: Set work item" })
      vim.keymap.set("n", "<leader>9wg", function()
        local work_item = get_current_work_item()
        if work_item then
          print(work_item)
          return
        end

        vim.notify("99: No current work item", vim.log.levels.INFO)
      end, { desc = "99: Show work item" })
      vim.keymap.set("n", "<leader>9wu", worker.update_work, { desc = "99: Update work item" })
      vim.keymap.set("n", "<leader>9ww", worker.search, { desc = "99: Run work search" })
      vim.keymap.set("n", "<leader>9wr", open_last_work_results, { desc = "99: Last work results" })
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
