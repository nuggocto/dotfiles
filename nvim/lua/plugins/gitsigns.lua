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
}
