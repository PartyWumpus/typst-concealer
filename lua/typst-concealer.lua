--- @class typstconcealer
local M = {}

--- @class autocmd_event
--- @field id integer
--- @field event string
--- @field group number | nil
--- @field match string
--- @field buf number
--- @field file string
--- @field data any

--- @type { [integer]: boolean }
M._enabled_buffers = {}

local is_tmux = vim.env.TMUX ~= nil

--- Sets up the constant typst prelude string
---@param color string? Any valid string that typst would accept, hex, name etc, otherwise defaults to colorscheme Default
local function setup_prelude(color)
  if (color == nil) then
    color = string.format('rgb("#%06X")', vim.api.nvim_get_hl(0, { name = "Normal" })["fg"])
  end
  -- FIXME: lists everything. agony. hope https://github.com/typst/typst/issues/5694 is resolved.
  M._prelude = '' ..
      '#set page(width: auto, height: auto, margin: 0pt, fill: none)\n' ..
      '#set text(' .. color .. ', font: "DejaVu Sans Mono", top-edge: "ascender", bottom-edge: "descender")\n' ..
      '#set line(stroke: ' .. color .. ')\n' ..
      '#set table(stroke: ' .. color .. ')\n' ..
      '#set circle(stroke: ' .. color .. ')\n' ..
      '#set ellipse(stroke: ' .. color .. ')\n' ..
      '#set line(stroke: ' .. color .. ')\n' ..
      '#set path(stroke: ' .. color .. ')\n' ..
      '#set polygon(stroke: ' .. color .. ')\n' ..
      '#set rect(stroke: ' .. color .. ')\n' ..
      '#set square(stroke: ' .. color .. ')\n' ..
      '#set box(stroke: ' .. color .. ')\n' ..
      ''
end



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

local vim_stdout = assert(vim.loop.new_tty(1, false))
--- Sends a kitty graphics message, adding the APC escape code stuff
--- @param message string
local function send_kitty_escape(message)
  if is_tmux then
    vim_stdout:write(tmux_escape("\x1b_G" .. message .. "\x1b\\"))
  else
    vim_stdout:write("\x1b_G" .. message .. "\x1b\\")
  end
end

---@param range Range4
---@return integer width
---@return integer height
local function range_to_dimensions(range)
  local start_row, start_col, end_row, end_col = range[1], range[2], range[3], range[4]
  local height = end_row - start_row + 1
  local width = 0
  if height == 1 then
    width = end_col - start_col
  else
    -- FIXME: don't just hardcode this
    width = 45
  end
  return width, height
end

-- Thanks https://github.com/3rd/image.nvim/issues/259 for showing how to do this with a code example!

--- TODO: for unhiding entire multiline regions in one go
local mark_groups = {}
--- Places the unicode characters to render a given image id over a range
--- @param image_id integer
--- @param range Range4
--- @param extmark_id? integer|nil
--- @param below? boolean should the text be virt_text or virt_lines
--- @return { [integer]: integer } array of extmark IDs that correspond to this image
local function place_image_extmarks(image_id, range, extmark_id, below)
  local start_row, start_col, end_row, end_col = range[1], range[2], range[3], range[4]
  local width, height = range_to_dimensions(range)
  --- @type { [integer]: integer }
  local ids = {}

  local hl_group = "typst-concealer-image-id-" .. tostring(image_id)
  -- encode image_id into the foreground color
  vim.api.nvim_set_hl(0, hl_group, { fg = string.format("#%06X", image_id) })

  if height == 1 then
    local line = ""
    for j = 0, width - 1 do
      line = line .. codes.placeholder .. codes.diacritics[1] .. codes.diacritics[j + 1]
    end
    if below then
      ids = { vim.api.nvim_buf_set_extmark(0, ns_id, start_row, start_col, {
        id = extmark_id,
        virt_lines = { { { line, hl_group } } },
        virt_text_pos = "overlay",
        invalidate = true,
        end_col = end_col,
        end_row = end_row
      }) }
    else
      ids = { vim.api.nvim_buf_set_extmark(0, ns_id, start_row, start_col, {
        id = extmark_id,
        virt_text = { { line, hl_group } },
        virt_text_pos = "inline",
        conceal = "",
        invalidate = true,
        end_col = end_col,
        end_row = end_row
      }) }
    end
  else
    for i = 0, height - 1 do
      local line = ""
      for j = 0, width - 1 do
        line = line .. codes.placeholder .. codes.diacritics[i + 1] .. codes.diacritics[j + 1]
      end
      -- TODO: I really hope there is a better way to do this?
      -- Mulitline conceal doesn't work, it only unhides the one line you look at,
      -- not the whole region. Multiline text replace with virt_lines/virt_text also doesn't
      -- work because virt lines displace instead of replacing. :(
      local id = vim.api.nvim_buf_set_extmark(0, ns_id, start_row + i, start_col, {
        virt_text = { { line, hl_group } },
        virt_text_pos = "overlay",
        invalidate = true,
        end_row = start_row + i
      })
      table.insert(ids, id)
    end
    for _, id in pairs(ids) do
      mark_groups[id] = ids
    end
  end

  return ids
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
--- @param image_id integer
--- @param range Range4
local function create_image(path, image_id, range)
  path = vim.base64.encode(path)
  local width, height = range_to_dimensions(range)
  -- read file
  send_kitty_escape("q=2,f=100,t=t,i=" .. image_id .. ";" .. path)
  -- render file at size
  send_kitty_escape("q=2,a=p,U=1,i=" .. image_id .. ",c=" .. width .. ",r=" .. height)
end

---comment
---@param image_id integer
local function clear_image(image_id)
  send_kitty_escape("q=2,a=d,d=i,i=" .. image_id)
  image_ids_in_use[image_id] = nil
end


local pid = vim.fn.getpid()
--- Generates a filename for a given image id and buffer
--- @param id integer
--- @param bufnr integer
--- @return string
local function typst_file_path(id, bufnr)
  return "/tmp/tty-graphics-protocol-typst-concealer-" .. pid .. "-" .. bufnr .. "-" .. id .. ".png"
end

--- @type vim.Diagnostic[]
local diagnostics = {}
--- @type integer
local remaining_images = 0


--- @param stderr uv_pipe_t
--- @param original_range Range4 This range may be out of date by this point, but it is good enough for diagnostics
--- @param image_id integer
--- @param bufnr integer
--- @param extmark_ids { [integer]: integer }
--- @param is_live_preview boolean
local function on_typst_exit(stderr, original_range, image_id, bufnr, extmark_ids, is_live_preview)
  stderr:shutdown()
  local err_bucket = {}
  stderr:read_start(function(err, data)
    if err then
      error(err)
    end
    if data then
      err_bucket[#err_bucket + 1] = data
    else
      stderr:close()
    end
  end)

  local check = assert(vim.uv.new_check())
  check:start(function()
    if not stderr:is_closing() then
      return
    end
    check:stop()
    check:close()

    local path = typst_file_path(image_id, bufnr)
    create_image(path, image_id, original_range)

    local err = table.concat(err_bucket)
    local diagnostic = nil
    if err ~= "" then
      diagnostic = {
        bufnr = bufnr,
        lnum = original_range[1],
        col = original_range[2],
        end_lnum = original_range[3],
        end_col = original_range[4],
        message = err,
        severity = "ERROR",
        namespace = ns_id,
        source = "typst-concealer"
      }
      vim.schedule(function()
        for _, id in ipairs(extmark_ids) do
          vim.api.nvim_buf_del_extmark(bufnr, ns_id, id)
        end
      end)
    end
    if (M.config.do_diagnostics) then
      if not is_live_preview then
        remaining_images = remaining_images - 1
        diagnostics[#diagnostics + 1] = diagnostic
        if remaining_images == 0 then
          vim.schedule(function()
            vim.diagnostic.set(ns_id, bufnr, diagnostics)
          end)
        end
      else
        vim.schedule(function()
          local temp = vim.deepcopy(diagnostics, true)
          temp[#temp + 1] = diagnostic
          vim.diagnostic.set(ns_id, bufnr, temp, { update_in_insert = true })
        end)
      end
    end
  end)
end

--- @param bufnr integer
--- @param id integer
--- @param orignal_range Range4
--- @param str string
--- @param extmark_ids { [integer]: integer }
--- @param is_live_preview boolean
local function compile_image(bufnr, id, orignal_range, str, extmark_ids, is_live_preview)
  -- TODO: use stdout maybe?
  local path = typst_file_path(id, bufnr)

  local stdin = vim.uv.new_pipe()
  local stdout = vim.uv.new_pipe()
  local stderr = vim.uv.new_pipe()

  local handle = vim.uv.spawn("typst", {
    stdio = { stdin, stdout, stderr },
    args = { "compile", "-", path },
  }, function(code, signal)
    on_typst_exit(stderr, orignal_range, id, bufnr, extmark_ids, is_live_preview)
  end)
  stdin:write({ M._prelude, str })
  stdin:close()
  stdout:close()
end

image_ids_in_use = {}
---@param bufnr integer
---@return integer
local function new_image_id(bufnr)
  for i = 1, 240 do
    if image_ids_in_use[i] == nil then
      image_ids_in_use[i] = bufnr
      return i
    end
  end
  -- Image id table full, overflow it
  print("[typst-concealer] too many image ids in use, overflowing")
  image_ids_in_use = { true }
  return 1
end

local math_query = vim.treesitter.query.parse("typst", "(math) @math")
local code_query = vim.treesitter.query.parse("typst", "[(code (_) @type) (math)] @code")

local function reset_buf(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  Live_preview_extmark_id = nil
  hidden_extmark_ids = {}
  diagnostics = {}

  for id, image_bufnr in pairs(image_ids_in_use) do
    if (bufnr == image_bufnr) then
      clear_image(id)
    end
  end
end

local function clear_diagnostics(bufnr)
  vim.schedule(function()
    vim.diagnostic.reset(ns_id, bufnr)
  end)
end

--- @param bufnr? integer Which buffer to render, defaulting to current buffer
local function render_buf(bufnr)
  bufnr = default(bufnr, vim.fn.bufnr())
  reset_buf(bufnr)
  clear_diagnostics(bufnr)
  if M._enabled_buffers[bufnr] ~= true then
    return
  end
  local parser = vim.treesitter.get_parser(bufnr)
  local tree = parser:parse()[1]:root()

  --- @type { [integer]: { [1]: Range4, [2]: integer } }
  local ranges = {}

  local prelude_count = {}

  for _, match, _ in code_query:iter_matches(tree, bufnr) do
    local type = match[2]:type()
    local start_row, start_col, end_row, end_col = match[2]:range()

    if (type == "math") then
      local image_id = new_image_id(bufnr)
      remaining_images = remaining_images + 1
      ranges[image_id] = { { start_row, start_col, end_row, end_col }, 0 }
    elseif (type == "code") then
      local code_flavour = match[1]:type()
      -- TODO: Consider special-casing "call", to deal with:
      -- Image, for larger images
      -- Links, for working links
      if (not vim.list_contains({ "let", "set", "import" }, code_flavour)) then
        local image_id = new_image_id(bufnr)
        remaining_images = remaining_images + 1
        ranges[image_id] = { { start_row, start_col, end_row, end_col }, 0 }
      end

      if (code_flavour == "let") then

      end
    end
  end

  for id, image in pairs(ranges) do
    local range, prelude_count = image[1], image[2]
    local extmark_ids = place_image_extmarks(id, range)
    local str = range_to_string(range, bufnr)
    vim.schedule(function()
      compile_image(bufnr, id, range, str, extmark_ids, false)
    end)
  end
  hide_extmarks_at_cursor()
end

hidden_extmark_ids = {}

function hide_extmarks_at_cursor()
  local bufnr = vim.fn.bufnr()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1
  local range_line = vim.fn.getpos('v')[2] - 1
  local extmarks
  if range_line > cursor_line then
    extmarks = vim.api.nvim_buf_get_extmarks(bufnr, ns_id, { cursor_line, 0 }, { range_line, -1 }, {
      overlap = true,
      details = true
    })
  else
    extmarks = vim.api.nvim_buf_get_extmarks(bufnr, ns_id, { range_line, 0, }, { cursor_line, -1 }, {
      overlap = true,
      details = true
    })
  end

  local new_hidden = {}

  for _, extmark in ipairs(extmarks) do
    --- @type integer, integer, integer, vim.api.keyset.extmark_details
    local id, row, col, opts = extmark[1], extmark[2], extmark[3], extmark[4]
    if hidden_extmark_ids[id] ~= nil then
      new_hidden[id] = hidden_extmark_ids[id]
      hidden_extmark_ids[id] = nil
    else
      new_hidden[id] = opts.virt_text
      hidden_extmark_ids[id] = nil
      vim.api.nvim_buf_set_extmark(bufnr, ns_id, row, col, {
        id = id,
        virt_text = { { "" } },

        end_row = opts.end_row,
        end_col = opts.end_col,
        conceal = opts.conceal,
        virt_text_pos = opts.virt_text_pos,
        invalidate = opts.invalidate,
      })
    end
  end

  -- show remaining extmarks not in selected lines
  for id, text in pairs(hidden_extmark_ids) do
    local m = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_id, id, { details = true })
    if #m ~= 0 then
      --- @type integer, integer, integer, vim.api.keyset.extmark_details
      local row, col, opts = m[1], m[2], m[3]
      vim.api.nvim_buf_set_extmark(bufnr, ns_id, row, col, {
        id = id,
        virt_text = text,

        end_row = opts.end_row,
        end_col = opts.end_col,
        conceal = opts.conceal,
        virt_text_pos = opts.virt_text_pos,
        invalidate = opts.invalidate,
      })
    end
  end

  hidden_extmark_ids = new_hidden
end

local function get_math_block_at_cursor()
  local parser = vim.treesitter.get_parser(0)
  local tree = parser:parse()[1]:root()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  cursor_pos = { cursor_pos[1] - 1, cursor_pos[2] }
  local element = tree:named_descendant_for_range(cursor_pos[1], cursor_pos[2], cursor_pos[3], cursor_pos[4])
  while true do
    if element == nil then
      return nil
    elseif element:type() ~= "math" then
      element = element:parent()
    else
      break
    end
  end
  if element ~= nil then
    return element:range()
  end

  return nil
end

--- @type {image_id: integer, extmark_id: integer} | nil
preview_image = nil

---comment
---@param bufnr integer
local function clear_live_typst_preview(bufnr)
  if preview_image ~= nil then
    clear_image(preview_image.image_id)
    vim.api.nvim_buf_del_extmark(bufnr, ns_id, preview_image.extmark_id)
    preview_image = nil
  end
end

local function render_live_typst_preview()
  local bufnr = vim.fn.bufnr()
  local start_row, start_col, end_row, end_col = get_math_block_at_cursor()
  if start_row == nil then
    clear_live_typst_preview(bufnr)
    return
  end
  if start_row ~= end_row then
    -- TODO:
    return
  end
  local range = { start_row, start_col, end_row, end_col }
  local str = range_to_string(range, bufnr)
  local prev_extmark = nil
  if preview_image ~= nil then
    clear_image(preview_image.image_id)
    prev_extmark = preview_image.extmark_id
  end
  local new_preview = {}
  new_preview.image_id = new_image_id(bufnr)
  new_preview.extmark_id = place_image_extmarks(new_preview.image_id, range, prev_extmark, true)[1]
  compile_image(bufnr, new_preview.image_id, range, str, {}, true)
  preview_image = new_preview
end

--- @class typstconfig
--- @field allow_missing_typst? boolean Allow the plugin to load without the typst binary in the path
--- @field do_diagnostics? boolean Should typst-concealer provide diagnostics on error?
--- @field color? string What color should typst-concealer render text/stroke with? (defaults to your color scheme's Normal color)
--- @field enabled_by_default boolean Should typst-concealer conceal newly opened buffers by default?

local augroup = vim.api.nvim_create_augroup("typst", { clear = true })

M.enable_buf = function(bufnr)
  M._enabled_buffers[bufnr] = true
  render_buf(bufnr)
end

M.disable_buf = function(bufnr)
  M._enabled_buffers[bufnr] = nil
  render_buf(bufnr)
end

--- Initializes typst-concealer
--- @param cfg typstconfig
--- @see typstconfig
function M.setup(cfg)
  local config = {
    allow_missing_typst = default(cfg.allow_missing_typst, false),
    do_diagnostics = default(cfg.do_diagnostics, true),
    enabled_by_default = default(cfg.enabled_by_default, true)
  }

  setup_prelude(cfg.color)
  M.config = config

  if not config.allow_missing_typst and vim.fn.executable('typst') ~= 1 then
    error("Typst executable not found in path, typst-concealer will not work")
  end

  if vim.v.vim_did_enter then
    local bufnr = vim.fn.bufnr()
    M._enabled_buffers[bufnr] = true
    render_buf(bufnr)
  end


  vim.api.nvim_create_autocmd("BufEnter",
    {
      pattern = "*.typ",
      group = augroup,
      desc = "typst-concealer render file on enter",
      callback = function()
        render_buf()
      end
    })

  vim.api.nvim_create_autocmd({ "BufNew", "VimEnter" },
    {
      pattern = "*.typ",
      group = augroup,
      desc = "typst-concealer enable file on creation",
      --- @param ev autocmd_event
      callback = function(ev)
        if M.config.enabled_by_default then
          M._enabled_buffers[ev.buf] = true
        end
      end
    })

  vim.api.nvim_create_autocmd("BufWritePost",
    {
      pattern = "*.typ",
      group = augroup,
      desc = "typst-concealer render file on enter",
      callback = function()
        vim.schedule(function()
          render_buf()
        end)
      end
    })

  vim.api.nvim_create_autocmd({ "CursorMovedI", "CursorMoved", "ModeChanged" },
    {
      pattern = "*.typ",
      group = augroup,
      desc = "typst-concealer unconceal on line hover",
      callback = function()
        hide_extmarks_at_cursor()
      end
    })

  vim.api.nvim_create_autocmd({ "CursorMoved", "ModeChanged" },
    {
      pattern = "*.typ",
      group = augroup,
      desc = "typst-concealer remove preview when not in insert mode",
      --- @param ev autocmd_event
      callback = function(ev)
        clear_live_typst_preview(ev.buf)
      end
    })

  vim.api.nvim_create_autocmd("CursorMovedI",
    {
      pattern = "*.typ",
      group = augroup,
      desc = "typst-concealer render live preview",
      callback = function()
        render_live_typst_preview()
      end
    })

  if (cfg.color == nil) then
    vim.api.nvim_create_autocmd("ColorScheme",
      {
        group = augroup,
        desc = "typst-concealer update colour scheme",
        callback = function()
          setup_prelude()
          -- TODO: check current render status
          render_buf(vim.fn.bufnr())
        end
      })
  end

  -- TODO: determine better way of doing this
  vim.opt.conceallevel = 2
  --vim.opt.concealcursor = "nv"
end

return M
