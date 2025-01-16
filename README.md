# Typst concealer

A neovim plugin that uses the new(ish) kitty unicode rendering protocol to render typst expressions inline.
Has live previews as you type in insert mode.

Is experimental. Also it should work with tmux :)

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
- Live previews when in insert mode (WIP)
- Supports top level set/let/import
- Renders code blocks
- Renders math blocks
- Can automatically match your nvim colorscheme

## Options
The options are mostly explained in the types, so either take a look in the code, (look for the `typstconfig` type) or get a good lua LSP and take a look what your autocomplete tells you.
The `styling_type` option is probably the most important one. It has three modes:
- "colorscheme" (default): Transparent background, and match the text color to your nvim colorscheme's color. This works reasonably well for most builtins, but many libraries aren't themed properly, or just look downright weird.
- "simple": Just remove the padding and get the width/height to fit of things to fit properly. Will have a white background, looking a little out of place in dark themes, but may be acceptable.
- "none": Do nothing, and completely rely on the user provided `#set`s. This is best for documents that never intend to be actually rendered as pdf/html, but just in neovim, otherwise the output of either neovim or the pdf is going to look rather strange.

In the future I may provide two options, one for inline typst, and one for multiline.
These styles are applied *after* all other rules are applied.

## Known issues / Todo list
- It doesn't actually hide the text beneath multiline images properly, so sometimes it's visible (if >75 chars)
- Mulitline typst things are just rendered at a fixed length of 75 characters, which is perhaps a little silly
- Multiline typst is not unhidden as a group, or given a preview
- When typst is unhidden, it doesn't rerender after an edit
- Assumes a mutable /tmp folder
- Breaks sometimes, pls report if any errors happen
- The rules about positioning of multiline/inline are totally different from what typst actually does


