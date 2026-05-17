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
        "docker-compose-language-service",
        "dockerfile-language-server",
        "hadolint",
        "helm-ls",
        "htmx-lsp",
        "kube-linter",
        "lua-language-server",
        "oxfmt",
        "oxlint",
        "ruff",
        "selene",
        "sqlfluff",
        "sqls",
        "stylua",
        "svelte-language-server",
        "terraform-ls",
        "tflint",
        "ty",
        "vtsls",
        "yaml-language-server",
        "yamlfmt",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    init = function()
      vim.filetype.add({
        filename = {
          ["compose.yaml"] = "yaml.docker-compose",
          ["compose.yml"] = "yaml.docker-compose",
          ["docker-compose.yaml"] = "yaml.docker-compose",
          ["docker-compose.yml"] = "yaml.docker-compose",
        },
      })
    end,
    opts = {
      servers = {
        clangd = { mason = false },
        gopls = { mason = false },
        ols = { mason = false },
        sqls = {},
        yamlls = { filetypes = { "yaml" } },
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
      opts.formatters_by_ft.yaml = { "yamlfmt" }
      opts.formatters_by_ft["yaml.ansible"] = { "yamlfmt" }

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
      opts.linters_by_ft.terraform = { "tflint" }
      opts.linters_by_ft.tf = { "tflint" }
      opts.linters_by_ft["terraform-vars"] = { "tflint" }
      opts.linters_by_ft["yaml.ansible"] = { "ansible_lint" }

      opts.linters = opts.linters or {}
      opts.linters.selene = opts.linters.selene or {}
      opts.linters.selene.condition = function(ctx)
        return vim.fs.find({ "selene.toml" }, { path = ctx.filename, upward = true })[1] ~= nil
      end

      opts.linters.sqlfluff = opts.linters.sqlfluff or {}
      opts.linters.sqlfluff.args = { "lint", "--dialect=ansi", "--format=json", "-" }

      opts.linters.terraform_validate = opts.linters.terraform_validate or {}
      opts.linters.terraform_validate.condition = function()
        return vim.fn.executable("terraform") == 1
      end
    end,
  },
}
