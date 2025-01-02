# Typst concealer

A simple neovim plugin that uses the new(ish) kitty unicode rendering protocol thing to render typst expressions inline.

Very experimental etc. Also it works with tmux :)

https://github.com/user-attachments/assets/94179603-2f41-43ff-9e5f-6dc4f31dc02d

## Installation
Lazy.nvim: `{ 'PartyWumpus/typst-concealer', config = function() require('typst-concealer').setup() end, event = "VeryLazy" },`

## Known issues
- It doesn't actually hide the text beneath images properly, so sometimes it's visible
- Multiline typst things are unhidden terribly in insert mode
- Mulitline typst things are just rendered at a fixed length of 75 characters, which is perhaps a little silly
- Doesn't render #images, even though it could
- It is weird
