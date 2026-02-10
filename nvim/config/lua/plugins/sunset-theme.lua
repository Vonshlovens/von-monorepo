-- Sunset Theme - Warm Red/Orange/Yellow palette
-- Matching Alacritty and Ghostty terminal configs
return {
  -- Configure LazyVim to use tokyonight
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
  -- Customize tokyonight with Sunset colors
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "night",
      transparent = false,
      terminal_colors = true,
      on_colors = function(colors)
        -- Background/foreground matching Alacritty/Ghostty
        colors.bg = "#1d1715"
        colors.bg_dark = "#15120f"
        colors.bg_float = "#15120f"
        colors.bg_popup = "#15120f"
        colors.bg_sidebar = "#15120f"
        colors.bg_statusline = "#15120f"
        colors.bg_highlight = "#2a2421"
        colors.fg = "#f4dcc4"
        colors.fg_dark = "#d4bca4"
        colors.fg_float = "#f4dcc4"
        colors.fg_gutter = "#594945"
        colors.fg_sidebar = "#d4bca4"

        -- Normal palette (palette 0-7)
        colors.black = "#1d1715"
        colors.red = "#f2594b"
        colors.green = "#e9b96e"
        colors.yellow = "#f9a03f"
        colors.blue = "#ff8c42"
        colors.magenta = "#e85d75"
        colors.cyan = "#ffa07a"
        colors.white = "#f4dcc4"

        -- Bright palette (palette 8-15)
        colors.terminal_black = "#594945"
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
        colors.bg_search = "#ff9e64"
        colors.border = "#594945"
        colors.border_highlight = "#ff8c42"

        -- Diagnostics / git
        colors.error = "#f2594b"
        colors.warning = "#f9a03f"
        colors.info = "#ff8c42"
        colors.hint = "#e9b96e"
        colors.git = { add = "#e9b96e", change = "#ff8c42", delete = "#f2594b" }
        colors.gitSigns = { add = "#e9b96e", change = "#ff8c42", delete = "#f2594b" }
      end,
      on_highlights = function(hl, c)
        -- Cursor matching Alacritty/Ghostty cursor-color
        hl.Cursor = { bg = "#ff8c42", fg = c.bg }
        hl.lCursor = { bg = "#ff8c42", fg = c.bg }
        hl.CursorIM = { bg = "#ff8c42", fg = c.bg }
        hl.TermCursor = { bg = "#ff8c42", fg = c.bg }
        hl.CursorLine = { bg = "#2a2421" }
        hl.CursorColumn = { bg = "#2a2421" }
        hl.CursorLineNr = { fg = "#ff8c42", bold = true }

        -- Selection matching Alacritty/Ghostty selection colors
        hl.Visual = { bg = "#594945", fg = "#ffe6d5" }
        hl.VisualNOS = { bg = "#594945", fg = "#ffe6d5" }

        -- Search matching Alacritty search.matches/focused_match
        hl.Search = { bg = "#ff9e64", fg = "#1d1715" }
        hl.IncSearch = { bg = "#e9b96e", fg = "#1d1715" }
        hl.CurSearch = { bg = "#e9b96e", fg = "#1d1715", bold = true }
        hl.Substitute = { bg = "#f2594b", fg = "#1d1715" }

        -- Line numbers
        hl.LineNr = { fg = "#594945" }
        hl.LineNrAbove = { fg = "#594945" }
        hl.LineNrBelow = { fg = "#594945" }

        -- Window borders and separators
        hl.WinSeparator = { fg = "#594945" }
        hl.VertSplit = { fg = "#594945" }
        hl.FloatBorder = { fg = "#ff8c42", bg = "#15120f" }
        hl.FloatTitle = { fg = "#ff8c42", bg = "#15120f", bold = true }

        -- Popup menu
        hl.Pmenu = { bg = "#15120f", fg = "#f4dcc4" }
        hl.PmenuSel = { bg = "#594945", fg = "#ffe6d5" }
        hl.PmenuSbar = { bg = "#2a2421" }
        hl.PmenuThumb = { bg = "#594945" }

        -- Statusline
        hl.StatusLine = { bg = "#15120f", fg = "#f4dcc4" }
        hl.StatusLineNC = { bg = "#15120f", fg = "#594945" }

        -- Tabline
        hl.TabLine = { bg = "#15120f", fg = "#594945" }
        hl.TabLineSel = { bg = "#2a2421", fg = "#ff8c42", bold = true }
        hl.TabLineFill = { bg = "#15120f" }

        -- Syntax highlighting with warm colors
        hl.Comment = { fg = "#8a7570", italic = true }
        hl.Keyword = { fg = "#ff6b5a", bold = true }
        hl.Function = { fg = "#ffcb6b" }
        hl.String = { fg = "#e9b96e" }
        hl.Number = { fg = "#ff9e64" }
        hl.Boolean = { fg = "#ff9e64" }
        hl.Type = { fg = "#ffa07a" }
        hl.Operator = { fg = "#ff8c42" }
        hl.Constant = { fg = "#ffb454" }
        hl.PreProc = { fg = "#e85d75" }
        hl.Special = { fg = "#ff9bc6" }
        hl.Delimiter = { fg = "#d4bca4" }
        hl.Title = { fg = "#ff8c42", bold = true }
        hl.Directory = { fg = "#ff8c42" }

        -- Diff
        hl.DiffAdd = { bg = "#2a2415" }
        hl.DiffChange = { bg = "#2a2421" }
        hl.DiffDelete = { bg = "#2d1b19" }
        hl.DiffText = { bg = "#3a3021" }

        -- Diagnostics
        hl.DiagnosticError = { fg = "#f2594b" }
        hl.DiagnosticWarn = { fg = "#f9a03f" }
        hl.DiagnosticInfo = { fg = "#ff8c42" }
        hl.DiagnosticHint = { fg = "#e9b96e" }

        -- Matching parens
        hl.MatchParen = { fg = "#ffcb6b", bg = "#594945", bold = true }

        -- Indent guides
        hl.IndentBlanklineChar = { fg = "#2a2421" }
        hl.IblIndent = { fg = "#2a2421" }
      end,
    },
  },
}
