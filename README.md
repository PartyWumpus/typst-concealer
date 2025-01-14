# Typst concealer

A simple neovim plugin that uses the new(ish) kitty unicode rendering protocol thing to render typst expressions inline.
Has live previews as you type in insert mode.

~~Very~~ Reasonably experimental etc. Also it should work with tmux :)

https://github.com/user-attachments/assets/94179603-2f41-43ff-9e5f-6dc4f31dc02d

## Installation
Lazy.nvim: `{ 'PartyWumpus/typst-concealer', config = function() require('typst-concealer').setup{} end, event = "VeryLazy" },`

## Known issues / Todo list
- It doesn't actually hide the text beneath multiline images properly, so sometimes it's visible (if >75 chars)
- Mulitline typst things are just rendered at a fixed length of 75 characters, which is perhaps a little silly
- Multiline typst is not unhidden as a group, or given a preview
- When typst is unhidden, it doesn't rerender after an edit
- Assumes a mutable /tmp folder
- Breaks sometimes, pls report if any errors happen
- The rules about positioning of multiline/inline are totally different from what typst actually does

## Features
- Live previews when in insert mode
- Renders code blocks
- Renders math blocks
- Matches your colorscheme
- Doesn't break very often

## Typst Feature Support

- ✅ Supported by this plugin
- 🟡 Supported "for free" by the typst treesitter implementation in a meaningful way
- ❌ Supported by neither
- 😀 Supported out of the box by neovim

| Feature | Examples | Support |
| ------------- | ------------- | ------------- |
Paragraph break |	Blank line | 😀
Strong emphasis |	`*strong*` | 🟡
Emphasis |	`_emphasis_` | 🟡
Raw text |	``` `print(1)` ``` | 🟡
Link |	`https://typst.app/` | `#link` doesn't really work, but regular links do
Label |	`<intro>` | ❌
Reference |	`@intro` | ❌
Heading |	`= Heading` | 🟡
Bullet list |	`- item` | ❌
Numbered list |	`+ item` | ❌
Term list	| `/ Term: description` | ❌
Math | `$x^2$` | ✅
Line break | `\` | ❌
Smart quote	| `'single'` or `"double"` | ❌
Symbol shorthand | `~`, `---`	| ❌
Code expression | `#rect(width: 1cm)` | ✅
Top-level let/set | `#let x = "twenty five"` | ❌ (todo next)
Character escape | `Tweet at us \#ad` | 🟡
Comment	| `/* block */`, `// line` | 🟡
