# Typst concealer

A neovim plugin that uses the new(ish) kitty unicode rendering protocol to render typst expressions inline.
Has live previews as you type in insert mode.

Requires nvim >=10.0, and only works properly in ghostty and kitty.

Works in tmux (partially, it will break if two instances of the plugin work as they will replace each-other's images), will not work in zellij as they have no way of passing through the escape sequences kitty needs to display images.

https://github.com/user-attachments/assets/94179603-2f41-43ff-9e5f-6dc4f31dc02d

## Installation
Lazy.nvim:
```lua
{
 'PartyWumpus/typst-concealer',
 config = function()
  require('typst-concealer').setup{}
 end,
 event = "VeryLazy"
},
```

### Keybinds
Typst-concealer can be disabled/enabled inside buffers. You can change the default with the `enabled_by_default` option.
```lua
-- example keybinds
vim.keymap.set("n", "<leader>ts", function()
 require('typst-concealer').enable_buf(vim.fn.bufnr())
end)
vim.keymap.set("n", "<leader>th", function()
 require('typst-concealer').disable_buf(vim.fn.bufnr())
end)
```

## Features
- Live previews when in insert mode (WIP, currently only works for single line previews)
- Supports top level set/let/import
- Renders code blocks
- Renders math blocks
- Can automatically match your nvim colorscheme
- Can provide diagnostics (although they can be disabled if you want to just use tinymist's superior diagnostics)

## Options
The options are mostly explained in the types, so either take a look in the code, (look for the `typstconfig` type) or get a good lua LSP and take a look what your autocomplete tells you.
The `styling_type` option is probably the most important one. It has three modes:
- "colorscheme" (default): Transparent background, and match the text color to your nvim colorscheme's color. This works reasonably well for most builtins, but many libraries aren't themed properly, or just look downright weird.
- "simple": Just remove the padding and get the width/height to fit of things to fit properly. Will have a white background, looking a little out of place in dark themes, but may be acceptable.
- "none": Do nothing, and completely rely on the user provided `#set`s. This is best for documents that never intend to be actually rendered as pdf/html, but just in neovim, otherwise the output of either neovim or the pdf is going to look rather strange.

These styles are applied *after* all other rules are applied.

## Known issues / Todo list
- When typst is unhidden, it doesn't rerender after an edit, which is doable
- Assumes a mutable /tmp folder
- Breaks sometimes, pls report if any errors happen
- The rules about positioning of multiline/inline are totally different from what typst actually does (when doing inline stuff, do it like this: `$ 2+2=4 $`, not `$2+2=4$`, or the plugin will render it weird. This is the complete opposite of what typst normally does, will be fixed eventually)
- If a file is closed while stuff is rendering, the plugin will freak out.
- If you are typing at the same time an image appears, you can get a bug where the message sent to the kitty image protocol gets displayed on the screen. It's difficult to reproduce, and I have no idea what to do about this.

