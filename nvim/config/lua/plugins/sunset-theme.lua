-- Sunset Theme - Matching the warm Ghostty theme
return {
  -- Configure LazyVim to use tokyonight
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
  -- Customize tokyonight with Ghostty's sunset colors
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "night",
      transparent = false,
      on_colors = function(colors)
        -- Match Ghostty's Sunset Theme colors
        colors.bg = "#1d1715"
        colors.bg_dark = "#15120f"
        colors.bg_highlight = "#2a2421"
        colors.fg = "#f4dcc4"
        colors.fg_dark = "#d4bca4"
        colors.fg_gutter = "#594945"

        -- Terminal colors from Ghostty palette
        colors.black = "#1d1715"
        colors.red = "#f2594b"
        colors.green = "#e9b96e"
        colors.yellow = "#f9a03f"
        colors.blue = "#ff8c42"
        colors.magenta = "#e85d75"
        colors.cyan = "#ffa07a"
        colors.white = "#f4dcc4"

        -- Bright variants
        colors.red1 = "#ff6b5a"
        colors.green1 = "#ffcb6b"
        colors.yellow1 = "#ffb454"
        colors.blue1 = "#ff9e64"
        colors.magenta1 = "#ff9bc6"
        colors.cyan1 = "#ffb38a"

        -- UI accents
        colors.orange = "#ff8c42"
        colors.comment = "#8a7570"
        colors.bg_visual = "#594945"
      end,
      on_highlights = function(hl, c)
        -- Cursor matching Ghostty
        hl.Cursor = { bg = "#ff8c42", fg = c.bg }
        hl.CursorLine = { bg = "#2a2421" }
        hl.CursorLineNr = { fg = "#ff8c42", bold = true }

        -- Selection matching Ghostty
        hl.Visual = { bg = "#594945", fg = "#ffe6d5" }

        -- Line numbers
        hl.LineNr = { fg = "#594945" }

        -- Syntax highlighting with warm colors
        hl.Comment = { fg = "#8a7570", italic = true }
        hl.Keyword = { fg = "#ff6b5a", bold = true }
        hl.Function = { fg = "#ffcb6b" }
        hl.String = { fg = "#e9b96e" }
        hl.Number = { fg = "#ff9e64" }
        hl.Type = { fg = "#ffa07a" }
        hl.Operator = { fg = "#ff8c42" }
      end,
    },
  },
}
