return {
  -- You can also add new plugins here as well:
  -- Add plugins, the lazy syntax
  -- "andweeb/presence.nvim",

  {
    "subnut/nvim-ghost.nvim",
    lazy = false,
  },
  {
    "kmonad/kmonad-vim",
    lazy = false,
  },
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      styles = {
        -- Style to be applied to different syntax groups
        -- Value is any valid attr-list value for `:help nvim_set_hl`
        comments = { italic = true },
        keywords = { italic = true },
        functions = {},
        variables = {},
        -- Background styles. Can be "dark", "transparent" or "normal"
        sidebars = "transparent", -- style for sidebars, see below
        floats = "transparent", -- style for floating windows
      },
      on_highlights = function(hl, _)
        local bg = "#000000"
        local fg = "#999999"
        hl.TelescopeNormal = {
          bg = bg,
          fg = fg,
        }
        hl.TelescopeBorder = {
          bg = bg,
          fg = fg,
        }
        hl.TelescopePromptNormal = {
          bg = bg,
        }
        hl.TelescopePromptBorder = {
          bg = bg,
          fg = fg,
        }
        hl.TelescopePromptTitle = {
          bg = bg,
          fg = fg,
        }
        hl.TelescopePreviewTitle = {
          bg = bg,
          fg = fg,
        }
        hl.TelescopeResultsTitle = {
          bg = bg,
          fg = fg,
        }
      end,
    },
  },
  -- {
  --   "ray-x/lsp_signature.nvim",
  --   event = "BufRead",
  --   config = function()
  --     require("lsp_signature").setup()
  --   end,
  -- },
}
