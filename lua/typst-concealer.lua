--- @class typstconcealer
local M = {}

local is_tmux = vim.env.TMUX ~= nil

local typst_prelude = "#set page(width: auto, height: auto, margin: 0pt, fill: none)\n#set text(white)\n"

local counter = 1

-- thanks neorg :)
local codes = {
  placeholder = "\u{0010EEEE}",
  diacritics = {
    "\u{00000305}",
    "\u{0000030D}",
    "\u{0000030E}",
    "\u{00000310}",
    "\u{00000312}",
    "\u{0000033D}",
    "\u{0000033E}",
    "\u{0000033F}",
    "\u{00000346}",
    "\u{0000034A}",
    "\u{0000034B}",
    "\u{0000034C}",
    "\u{00000350}",
    "\u{00000351}",
    "\u{00000352}",
    "\u{00000357}",
    "\u{0000035B}",
    "\u{00000363}",
    "\u{00000364}",
    "\u{00000365}",
    "\u{00000366}",
    "\u{00000367}",
    "\u{00000368}",
    "\u{00000369}",
    "\u{0000036A}",
    "\u{0000036B}",
    "\u{0000036C}",
    "\u{0000036D}",
    "\u{0000036E}",
    "\u{0000036F}",
    "\u{00000483}",
    "\u{00000484}",
    "\u{00000485}",
    "\u{00000486}",
    "\u{00000487}",
    "\u{00000592}",
    "\u{00000593}",
    "\u{00000594}",
    "\u{00000595}",
    "\u{00000597}",
    "\u{00000598}",
    "\u{00000599}",
    "\u{0000059C}",
    "\u{0000059D}",
    "\u{0000059E}",
    "\u{0000059F}",
    "\u{000005A0}",
    "\u{000005A1}",
    "\u{000005A8}",
    "\u{000005A9}",
    "\u{000005AB}",
    "\u{000005AC}",
    "\u{000005AF}",
    "\u{000005C4}",
    "\u{00000610}",
    "\u{00000611}",
    "\u{00000612}",
    "\u{00000613}",
    "\u{00000614}",
    "\u{00000615}",
    "\u{00000616}",
    "\u{00000617}",
    "\u{00000657}",
    "\u{00000658}",
    "\u{00000659}",
    "\u{0000065A}",
    "\u{0000065B}",
    "\u{0000065D}",
    "\u{0000065E}",
    "\u{000006D6}",
    "\u{000006D7}",
    "\u{000006D8}",
    "\u{000006D9}",
    "\u{000006DA}",
    "\u{000006DB}",
    "\u{000006DC}",
    "\u{000006DF}",
    "\u{000006E0}",
    "\u{000006E1}",
    "\u{000006E2}",
    "\u{000006E4}",
    "\u{000006E7}",
    "\u{000006E8}",
    "\u{000006EB}",
    "\u{000006EC}",
    "\u{00000730}",
    "\u{00000732}",
    "\u{00000733}",
    "\u{00000735}",
    "\u{00000736}",
    "\u{0000073A}",
    "\u{0000073D}",
    "\u{0000073F}",
    "\u{00000740}",
    "\u{00000741}",
    "\u{00000743}",
    "\u{00000745}",
    "\u{00000747}",
    "\u{00000749}",
    "\u{0000074A}",
    "\u{000007EB}",
    "\u{000007EC}",
    "\u{000007ED}",
    "\u{000007EE}",
    "\u{000007EF}",
    "\u{000007F0}",
    "\u{000007F1}",
    "\u{000007F3}",
    "\u{00000816}",
    "\u{00000817}",
    "\u{00000818}",
    "\u{00000819}",
    "\u{0000081B}",
    "\u{0000081C}",
    "\u{0000081D}",
    "\u{0000081E}",
    "\u{0000081F}",
    "\u{00000820}",
    "\u{00000821}",
    "\u{00000822}",
    "\u{00000823}",
    "\u{00000825}",
    "\u{00000826}",
    "\u{00000827}",
    "\u{00000829}",
    "\u{0000082A}",
    "\u{0000082B}",
    "\u{0000082C}",
    "\u{0000082D}",
    "\u{00000951}",
    "\u{00000953}",
    "\u{00000954}",
    "\u{00000F82}",
    "\u{00000F83}",
    "\u{00000F86}",
    "\u{00000F87}",
    "\u{0000135D}",
    "\u{0000135E}",
    "\u{0000135F}",
    "\u{000017DD}",
    "\u{0000193A}",
    "\u{00001A17}",
    "\u{00001A75}",
    "\u{00001A76}",
    "\u{00001A77}",
    "\u{00001A78}",
    "\u{00001A79}",
    "\u{00001A7A}",
    "\u{00001A7B}",
    "\u{00001A7C}",
    "\u{00001B6B}",
    "\u{00001B6D}",
    "\u{00001B6E}",
    "\u{00001B6F}",
    "\u{00001B70}",
    "\u{00001B71}",
    "\u{00001B72}",
    "\u{00001B73}",
    "\u{00001CD0}",
    "\u{00001CD1}",
    "\u{00001CD2}",
    "\u{00001CDA}",
    "\u{00001CDB}",
    "\u{00001CE0}",
    "\u{00001DC0}",
    "\u{00001DC1}",
    "\u{00001DC3}",
    "\u{00001DC4}",
    "\u{00001DC5}",
    "\u{00001DC6}",
    "\u{00001DC7}",
    "\u{00001DC8}",
    "\u{00001DC9}",
    "\u{00001DCB}",
    "\u{00001DCC}",
    "\u{00001DD1}",
    "\u{00001DD2}",
    "\u{00001DD3}",
    "\u{00001DD4}",
    "\u{00001DD5}",
    "\u{00001DD6}",
    "\u{00001DD7}",
    "\u{00001DD8}",
    "\u{00001DD9}",
    "\u{00001DDA}",
    "\u{00001DDB}",
    "\u{00001DDC}",
    "\u{00001DDD}",
    "\u{00001DDE}",
    "\u{00001DDF}",
    "\u{00001DE0}",
    "\u{00001DE1}",
    "\u{00001DE2}",
    "\u{00001DE3}",
    "\u{00001DE4}",
    "\u{00001DE5}",
    "\u{00001DE6}",
    "\u{00001DFE}",
    "\u{000020D0}",
    "\u{000020D1}",
    "\u{000020D4}",
    "\u{000020D5}",
    "\u{000020D6}",
    "\u{000020D7}",
    "\u{000020DB}",
    "\u{000020DC}",
    "\u{000020E1}",
    "\u{000020E7}",
    "\u{000020E9}",
    "\u{000020F0}",
    "\u{00002CEF}",
    "\u{00002CF0}",
    "\u{00002CF1}",
    "\u{00002DE0}",
    "\u{00002DE1}",
    "\u{00002DE2}",
    "\u{00002DE3}",
    "\u{00002DE4}",
    "\u{00002DE5}",
    "\u{00002DE6}",
    "\u{00002DE7}",
    "\u{00002DE8}",
    "\u{00002DE9}",
    "\u{00002DEA}",
    "\u{00002DEB}",
    "\u{00002DEC}",
    "\u{00002DED}",
    "\u{00002DEE}",
    "\u{00002DEF}",
    "\u{00002DF0}",
    "\u{00002DF1}",
    "\u{00002DF2}",
    "\u{00002DF3}",
    "\u{00002DF4}",
    "\u{00002DF5}",
    "\u{00002DF6}",
    "\u{00002DF7}",
    "\u{00002DF8}",
    "\u{00002DF9}",
    "\u{00002DFA}",
    "\u{00002DFB}",
    "\u{00002DFC}",
    "\u{00002DFD}",
    "\u{00002DFE}",
    "\u{00002DFF}",
    "\u{0000A66F}",
    "\u{0000A67C}",
    "\u{0000A67D}",
    "\u{0000A6F0}",
    "\u{0000A6F1}",
    "\u{0000A8E0}",
    "\u{0000A8E1}",
    "\u{0000A8E2}",
    "\u{0000A8E3}",
    "\u{0000A8E4}",
    "\u{0000A8E5}",
    "\u{0000A8E6}",
    "\u{0000A8E7}",
    "\u{0000A8E8}",
    "\u{0000A8E9}",
    "\u{0000A8EA}",
    "\u{0000A8EB}",
    "\u{0000A8EC}",
    "\u{0000A8ED}",
    "\u{0000A8EE}",
    "\u{0000A8EF}",
    "\u{0000A8F0}",
    "\u{0000A8F1}",
    "\u{0000AAB0}",
    "\u{0000AAB2}",
    "\u{0000AAB3}",
    "\u{0000AAB7}",
    "\u{0000AAB8}",
    "\u{0000AABE}",
    "\u{0000AABF}",
    "\u{0000AAC1}",
    "\u{0000FE20}",
    "\u{0000FE21}",
    "\u{0000FE22}",
    "\u{0000FE23}",
    "\u{0000FE24}",
    "\u{0000FE25}",
    "\u{0000FE26}",
    "\u{00010A0F}",
    "\u{00010A38}",
    "\u{0001D185}",
    "\u{0001D186}",
    "\u{0001D187}",
    "\u{0001D188}",
    "\u{0001D189}",
    "\u{0001D1AA}",
    "\u{0001D1AB}",
    "\u{0001D1AC}",
    "\u{0001D1AD}",
    "\u{0001D242}",
    "\u{0001D243}",
    "\u{0001D244}",
  },
}

--- Takes in a value, and if it is nil, return the provided default
--- @generic T
--- @param val T?
--- @param default_val T
--- @return T
local function default(val, default_val)
  if val == nil then return default_val end
  return val
end

local ns_id = vim.api.nvim_create_namespace("typst")

--- Escapes a given escape sequence so tmux will pass it through
--- @param message string
--- @return string
local tmux_escape = function(message)
  -- Thanks image.nvim
  return "\x1bPtmux;" .. message:gsub("\x1b", "\x1b\x1b") .. "\x1b\\"
end

local stdout = vim.loop.new_tty(1, false)
--- Sends a kitty graphics message, adding the APC escape code stuff
--- @param message string
local function send_kitty_escape(message)
  if is_tmux then
    stdout:write(tmux_escape("\x1b_G" .. message .. "\x1b\\"))
  else
    stdout:write("\x1b_G" .. message .. "\x1b\\")
  end
end

-- Thanks https://github.com/3rd/image.nvim/issues/259 for showing how to do this with a code example!

--- Places the unicode characters to render a given image id over a range
--- @param image_id integer
--- @param range Range4
local function render_image(image_id, range)
  local start_row, start_col, end_row, end_col = range[1], range[2], range[3], range[4]
  local height = end_row - start_row + 1
  local width, y, x
  if height == 1 then
    width = end_col - start_col
    y = start_row
    x = start_col
  else
    width = 45 -- TODO: do this better
    y = start_row
    x = 0
  end
  send_kitty_escape("q=2,a=p,U=1,i=" .. image_id .. ",c=" .. width .. ",r=" .. height)

  local hl_group = "image-nvim-image-id-" .. tostring(image_id)
  -- encode image_id into the foreground color
  vim.api.nvim_set_hl(0, hl_group, { fg = string.format("#%06X", image_id) })
  for i = 0, height - 1 do
    local line = ""
    for j = 0, width - 1 do
      line = line .. codes.placeholder .. codes.diacritics[i + 1] .. codes.diacritics[j + 1]
    end
    vim.api.nvim_buf_set_extmark(0, ns_id, y + i, x, {
      virt_text = { { line, hl_group } },
      virt_text_pos = "overlay",
      invalidate = true,
    })
  end
end

--- Takes in a range and returns the string contained within that range
--- @param range Range4
--- @param bufnr integer
--- @return string
local function range_to_string(range, bufnr)
  local start_row, start_col, end_row, end_col = range[1], range[2], range[3], range[4]
  local content = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
  if start_row == end_row then
    content[1] = string.sub(content[1], start_col + 1, end_col)
  else
    content[1] = string.sub(content[1], start_col + 1)
    content[#content] = string.sub(content[#content], 0, end_col)
  end
  return table.concat(content, "\n")
end

--- Tells terminal to read the image and link image id -> image
--- @param path string
--- @param id integer
local function create_image(path, id)
  path = vim.base64.encode(path)
  send_kitty_escape("q=2,f=100,t=f,i=" .. id .. ";" .. path)
end


local pid = vim.fn.getpid()
--- Generates a filename for a given image id and buffer
--- @param id integer
--- @param bufnr integer
--- @return string
local function typst_file_path(id, bufnr)
  return "/tmp/typst-concealer-" .. pid .. "-" .. bufnr .. "-" .. id .. ".png"
end

--- @param buf? integer Which buffer to render, defaulting to current buffer
local function render_buf(buf)
  vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
  local bufnr = default(buf, vim.fn.bufnr())
  local parser = vim.treesitter.get_parser(bufnr)
  local tree = parser:parse({})

  --- @type { [integer]: Range4 }
  local rows = {}

  ---@type { [integer]: vim.SystemObj }
  local waits = {}

  local query = vim.treesitter.query.parse("typst", "(math) @math")
  for _, node in query:iter_captures(tree[1]:root()) do
    local start_row, start_col, end_row, end_col = node:range()
    local str = range_to_string({ start_row, start_col, end_row, end_col }, bufnr)
    local id = counter
    counter = counter + 1
    local path = typst_file_path(id, bufnr)
    --local obj = vim.system({ "typst", "--color=always", "compile", "-", path }, {
    local obj = vim.system({ "typst", "compile", "-", path }, {
      stdin = { typst_prelude, str },
      timeout = 1000,
    })
    waits[id] = obj
    rows[id] = { start_row, start_col, end_row, end_col }
  end

  --- @type vim.Diagnostic[]
  local diagnostics = {}

  for id, obj in pairs(waits) do
    local status = obj:wait()
    if status.code == 124 then
      local range = rows[id]
      diagnostics[#diagnostics + 1] = {
        bufnr = bufnr,
        lnum = tonumber(range[1]),
        col = tonumber(range[2]),
        end_lnum = tonumber(range[3]),
        end_col = tonumber(range[4]),
        message = "Typst timed out while trying to compile this (1s)",
        severity = "WARN",
        namespace = ns_id,
        source = "typst-concealer"
      }
      rows[id] = nil -- don't render if failed
    elseif status.stderr ~= "" then
      local range = rows[id]
      diagnostics[#diagnostics + 1] = {
        bufnr = bufnr,
        lnum = tonumber(range[1]),
        col = tonumber(range[2]),
        end_lnum = tonumber(range[3]),
        end_col = tonumber(range[4]),
        message = status.stderr,
        severity = "ERROR",
        namespace = ns_id,
        source = "typst-concealer"
      }
      rows[id] = nil -- don't render if failed
    end
  end
  vim.diagnostic.set(ns_id, bufnr, diagnostics)

  for id, range in pairs(rows) do
    local path = typst_file_path(id, bufnr)
    create_image(path, id)
    render_image(id, range)
  end
end

--- @class typstconfig
--- @field render_on_enter? boolean Should typst-concealer render all typst blocks when a file is first entered?
--- @field rerender_on_save? boolean Should typst-concealer rerender all typst blocks when a file is saved?
--- @field allow_missing_typst? boolean Allow the plugin to load without the typst binary in the path

local augroup = vim.api.nvim_create_augroup("typst", { clear = true })

--- Initializes typst-concealer
--- @param cfg typstconfig
--- @see typstconfig
function M.setup(cfg)
  cfg = {
    render_on_enter = default(cfg.render_on_enter, true),
    rerender_on_save = default(cfg.rerender_on_save, true),
    allow_missing_typst = default(cfg.allow_missing_typst, false),
  }

  if not cfg.allow_missing_typst and vim.fn.executable('typst') ~= 1 then
    error("Typst executable not found in path, typst-concealer will not work")
  end


  if cfg.render_on_enter then
    vim.api.nvim_create_autocmd("BufEnter",
      {
        pattern = "*.typ",
        group = augroup,
        desc = "typst-concealer render file on enter",
        callback = function()
          render_buf()
        end
      })
  end

  if cfg.rerender_on_save then
    vim.api.nvim_create_autocmd("BufWritePost",
      {
        pattern = "*.typ",
        group = augroup,
        desc = "typst-concealer render file on enter",
        callback = function()
          render_buf()
        end
      })
  end


  vim.keymap.set("n", "<leader>tt", render_buf, { desc = "[typst-concealer] re-render" })
  vim.keymap.set("n", "<leader>tr", function()
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
  end, { desc = "[typst-concealer] clear" })
end

return M
