return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "c", "cpp", "odin" } },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "astro-language-server",
        "debugpy",
        "htmx-lsp",
        "lua-language-server",
        "oxfmt",
        "oxlint",
        "ruff",
        "selene",
        "sqlfluff",
        "sqls",
        "stylua",
        "svelte-language-server",
        "ty",
        "vtsls",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = { mason = false },
        gopls = { mason = false },
        ols = { mason = false },
        sqls = {},
        zls = { mason = false },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.c = { "clang_format" }
      opts.formatters_by_ft.cpp = { "clang_format" }
      opts.formatters_by_ft.python = { "ruff_organize_imports", "ruff_format" }
      opts.formatters_by_ft.sql = { "sqlfluff" }

      opts.formatters = opts.formatters or {}
      opts.formatters.sqlfluff = {
        args = { "format", "--dialect=ansi", "-" },
        require_cwd = false,
      }
    end,
  },
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.lua = { "selene" }

      opts.linters = opts.linters or {}
      opts.linters.selene = opts.linters.selene or {}
      opts.linters.selene.condition = function(ctx)
        return vim.fs.find({ "selene.toml" }, { path = ctx.filename, upward = true })[1] ~= nil
      end

      opts.linters.sqlfluff = opts.linters.sqlfluff or {}
      opts.linters.sqlfluff.args = { "lint", "--dialect=ansi", "--format=json", "-" }
    end,
  },
}
