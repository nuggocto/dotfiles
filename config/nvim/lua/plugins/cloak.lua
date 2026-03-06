return {
  {
    "laytan/cloak.nvim",
    opts = {
      cloak_character = "*",
      cloak_telescope = true,
      patterns = {
        {
          file_pattern = {
            ".env*",
            "*.env",
            ".envrc",
            ".dev.vars",
          },
          cloak_pattern = "=.+",
        },
      },
    },
    config = function(_, opts)
      require("cloak").setup(opts)
    end,
  },
}
