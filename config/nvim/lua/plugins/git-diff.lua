return {
  {
    "lewis6991/gitsigns.nvim",
    optional = true,
    keys = {
      {
        "<leader>gd",
        function()
          require("gitsigns").diffthis()
        end,
        desc = "Git diff current file",
      },
      {
        "<leader>gq",
        "<cmd>diffoff!<cr>",
        desc = "Git diff close",
      },
    },
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    keys = {
      {
        "<leader>gD",
        "<cmd>DiffviewOpen<cr>",
        desc = "Git diff review",
      },
      {
        "<leader>gH",
        "<cmd>DiffviewFileHistory %<cr>",
        desc = "Git file history",
      },
      {
        "<leader>gC",
        "<cmd>DiffviewClose<cr>",
        desc = "Git close review",
      },
    },
    opts = {
      view = {
        default = {
          disable_diagnostics = true,
        },
        file_history = {
          disable_diagnostics = true,
        },
        merge_tool = {
          disable_diagnostics = true,
        },
      },
    },
  },
}
