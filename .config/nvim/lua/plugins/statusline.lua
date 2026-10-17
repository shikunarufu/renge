return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local c = require("kanagawa.colors").setup({ theme = "dragon" }).palette

      local function mode(color)
        return {
          a = { fg = color, bg = "NONE", gui = "bold" },
          b = { fg = color, bg = "NONE" },
          c = { fg = c.dragonWhite, bg = "NONE" },
        }
      end

      opts.options = opts.options or {}
      opts.options.theme = {
        normal = mode(c.dragonBlue2),
        insert = mode(c.dragonGreen2),
        visual = mode(c.dragonViolet),
        replace = mode(c.dragonRed),
        command = mode(c.dragonYellow),
        inactive = mode(c.dragonAsh),
      }
      opts.options.section_separators = ""
      opts.options.component_separators = ""
    end,
  },
}
