return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = {
          settings = {
            gopls = {
              build = {
                -- Removed experimentalWorkspaceModule (deprecated in gopls v0.15+).
                -- gopls now handles multi-module repos via go.work automatically.
                allowModfileModifications = false,
                allowInferral = false,
              },
              ui = {
                diagnostic = {
                  annotations = {
                    bounds = true,
                    escape = true,
                    inline = true,
                    nil = true,
                  },
                },
              },
            },
          },
        },
      },
    },
  },

  -- Fix golangci-lint timing out before it can analyze packages
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        golangcilint = {
          prepend_args = {
            "--timeout=5m",
            "--issues-exit-code=0",
          },
        },
      },
    },
  },

  -- Explicitly set Go formatters so there's no ambiguity
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        go = { "goimports", "gofumpt" },
      },
    },
  },
}
