-- set vim options here (vim.<first_key>.<second_key> = value)
return {
  opt = {
    guifont = [[Iosevka\ Nerd\ Font:h13:l]],
    -- set to true or false etc.
    relativenumber = true, -- sets vim.opt.relativenumber
    number = true, -- sets vim.opt.number
    spell = false, -- sets vim.opt.spell
    signcolumn = "auto", -- sets vim.opt.signcolumn to auto
    wrap = false, -- sets vim.opt.wrap
    shiftwidth = 2,
    tabstop = 2,
    softtabstop = 2,
    scrolljump = 1,
    scrolloff = 3,
    winblend = 20,
    pumblend = 20,
    swapfile = false,
    backup = false,
    writebackup = false,
  },
  g = {
    neovide_cursor_vfx_mode = "ripple",
    neovide_transparency = 0.95,
    neovide_refresh_rate = 60,
    neovide_cursor_animation_length = 0.007,
    neovide_floating_blur_amount_x = 3.0,
    neovide_floating_blur_amount_y = 3.0,
    mapleader = " ", -- sets vim.g.mapleader
    autoformat_enabled = true, -- enable or disable auto formatting at start (lsp.formatting.format_on_save must be enabled)
    cmp_enabled = true, -- enable completion at start
    autopairs_enabled = true, -- enable autopairs at start
    diagnostics_enabled = true, -- enable diagnostics at start
    status_diagnostics_enabled = true, -- enable diagnostics in statusline
    icons_enabled = true, -- disable icons in the UI (disable if no nerd font is available, requires :PackerSync after changing)
    ui_notifications_enabled = true, -- disable notifications when toggling UI elements
    heirline_bufferline = false, -- enable new heirline based bufferline (requires :PackerSync after changing)
  },
}
-- If you need more control, you can use the function()...end notation
-- return function(local_vim)
--   local_vim.opt.relativenumber = true
--   local_vim.g.mapleader = " "
--   local_vim.opt.whichwrap = vim.opt.whichwrap - { 'b', 's' } -- removing option from list
--   local_vim.opt.shortmess = vim.opt.shortmess + { I = true } -- add to option list
--
--   return local_vim
-- end
