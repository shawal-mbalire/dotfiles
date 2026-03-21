return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      angularls = {
        -- 1. Find the root, even from the top of the monorepo
        root_dir = function(fname)
          local util = require("lspconfig.util")
          return util.root_pattern("angular.json", "nx.json", "package.json")(fname)
        end,

        -- 2. Tell the server exactly where your Angular libraries live
        on_new_config = function(new_config, new_root_dir)
          local paths = table.concat({
            new_root_dir .. "/node_modules",
            vim.fn.getcwd() .. "/node_modules",
            vim.fn.getcwd() .. "/client/node_modules", -- Hardcoded for your structure
          }, ",")

          new_config.cmd = {
            "ngserver",
            "--stdio",
            "--tsProbeLocations",
            paths,
            "--ngProbeLocations",
            paths,
          }
        end,
      },
      nushell = {},
    },
  },
}
