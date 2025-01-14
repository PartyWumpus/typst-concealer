# Typst concealer

A simple neovim plugin that uses the new(ish) kitty unicode rendering protocol thing to render typst expressions inline.
Has live previews as you type in insert mode.

Very experimental etc. Also it works with tmux :)

https://github.com/user-attachments/assets/94179603-2f41-43ff-9e5f-6dc4f31dc02d

## Installation
Lazy.nvim: `{ 'PartyWumpus/typst-concealer', config = function() require('typst-concealer').setup() end, event = "VeryLazy" },`

## Known issues / Todo list
- It doesn't actually hide the text beneath multiline images properly, so sometimes it's visible (if >75 chars)
- Mulitline typst things are just rendered at a fixed length of 75 characters, which is perhaps a little silly
- Multiline typst is not unhidden as a group, or given a preview
- When typst is unhidden, it doesn't rerender after an edit
- Assumes a mutable /tmp folder
- Breaks sometimes, pls report if any errors happen
- The rules about positioning of multiline/inline are totally different from what typst actually does
