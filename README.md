# Typst concealer

A simple neovim plugin that uses the new(ish) kitty unicode rendering protocol thing to render typst expressions inline.

Very experimental etc. Also it works with tmux :)

https://github.com/user-attachments/assets/94179603-2f41-43ff-9e5f-6dc4f31dc02d

## Installation
Lazy.nvim: `{ 'PartyWumpus/typst-concealer', config = function() require('typst-concealer').setup() end, event = "VeryLazy" },`

## Known issues / Todo list
- It doesn't actually hide the text beneath images properly, so sometimes it's visible
- When typst is unhidden, it doesn't rerender on edit even though that would be cool
- Multiline typst things are unhidden terribly in insert mode
- Mulitline typst things are just rendered at a fixed length of 75 characters, which is perhaps a little silly
- The source text for an error is still covered by invisible characters
- Assumes a mutable /tmp folder
- Doesn't render #images
