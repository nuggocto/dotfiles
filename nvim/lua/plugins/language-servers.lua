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
        "elixir-ls",
        "helm-ls",
        "htmx-lsp",
        "js-debug-adapter",
        "kube-linter",
        "lua-language-server",
        "oxlint",
        "postgres-language-server",
        "ruff",
        "selene",
        "sqls",
        "svelte-language-server",
        "terraform-ls",
        "ty",
        "yaml-language-server",
        "yamlfmt",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    init = function()
      vim.filetype.add({
        extension = {
          pgsql = "pgsql",
          psql = "pgsql",
        },
        filename = {
          ["compose.yaml"] = "yaml.docker-compose",
          ["compose.yml"] = "yaml.docker-compose",
          ["docker-compose.yaml"] = "yaml.docker-compose",
          ["docker-compose.yml"] = "yaml.docker-compose",
        },
      })
      vim.treesitter.language.register("sql", "pgsql")
    end,
    opts = {
      servers = {
        clangd = { mason = false },
        denols = {
          root_dir = function(bufnr, on_dir)
            local root = vim.fs.root(bufnr, { "deno.json", "deno.jsonc" })
            if root then
              on_dir(root)
            end
          end,
          settings = {
            deno = {
              enable = true,
              lint = false,
            },
          },
        },
        gopls = { mason = false },
        expert = { enabled = false },
        htmx = {
          filetypes = { "html", "templ", "astro", "svelte", "typescriptreact", "javascriptreact" },
        },
        ols = { mason = false },
        postgres_lsp = {
          filetypes = { "sql", "pgsql" },
          root_markers = { "postgres-language-server.jsonc", "postgrestools.jsonc", ".sqlfluff", ".git" },
          workspace_required = false,
        },
        sqls = {},
        tsgo = {},
        vtsls = { enabled = false },
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
      opts.formatters_by_ft.elixir = { "mix" }
      opts.formatters_by_ft.odin = { "odinfmt" }
      opts.formatters_by_ft.python = { "ruff_organize_imports", "ruff_format" }
      opts.formatters_by_ft.sql = { "sqlfluff_postgres" }
      opts.formatters_by_ft.pgsql = { "sqlfluff_postgres" }
      opts.formatters_by_ft.yaml = { "yamlfmt" }
      opts.formatters_by_ft["yaml.ansible"] = { "yamlfmt" }

      opts.formatters = opts.formatters or {}
      opts.formatters.sqlfluff = {
        args = { "format", "--dialect=ansi", "-" },
        require_cwd = false,
      }
      opts.formatters.sqlfluff_postgres = {
        inherit = "sqlfluff",
        args = { "format", "--dialect=postgres", "-" },
        require_cwd = false,
      }
    end,
  },
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      local function add_linters(ft, names)
        opts.linters_by_ft[ft] = opts.linters_by_ft[ft] or {}
        for _, name in ipairs(names) do
          if not vim.tbl_contains(opts.linters_by_ft[ft], name) then
            table.insert(opts.linters_by_ft[ft], name)
          end
        end
      end

      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.lua = { "selene" }
      opts.linters_by_ft.sql = { "sqlfluff_postgres" }
      opts.linters_by_ft.pgsql = { "sqlfluff_postgres" }
      add_linters("terraform", { "terraform_validate", "tflint" })
      add_linters("tf", { "terraform_validate", "tflint" })
      opts.linters_by_ft["terraform-vars"] = { "tflint" }
      opts.linters_by_ft["yaml.ansible"] = { "ansible_lint" }

      opts.linters = opts.linters or {}
      opts.linters.selene = opts.linters.selene or {}
      opts.linters.selene.condition = function(ctx)
        return vim.fs.find({ "selene.toml" }, { path = ctx.filename, upward = true })[1] ~= nil
      end

      opts.linters.sqlfluff = opts.linters.sqlfluff or {}
      opts.linters.sqlfluff.args = { "lint", "--dialect=ansi", "--format=json", "-" }

      opts.linters.sqlfluff_postgres = {
        cmd = "sqlfluff",
        args = { "lint", "--dialect=postgres", "--format=json", "-" },
        stdin = true,
        ignore_exitcode = true,
        parser = function(output, bufnr)
          return require("lint.linters.sqlfluff").parser(output, bufnr)
        end,
      }

      opts.linters.terraform_validate = opts.linters.terraform_validate or {}
      opts.linters.terraform_validate.condition = function()
        return vim.fn.executable("terraform") == 1
      end
    end,
  },
}
