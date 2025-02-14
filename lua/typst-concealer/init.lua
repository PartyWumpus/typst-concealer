--- @class typstconcealer
local M = {}

local pngData = require('typst-concealer.png-lua')
local kitty_codes = require('typst-concealer.kitty-codes')
local truecolor = vim.env.COLORTERM == "truecolor" or vim.env.COLORTERM == "24bit"
-- Just hope there aren't collisions...
-- This is a poor solution
-- FIXME: use some sort of incrementing counter somehow
local pid = vim.fn.getpid() % 256
local full_pid = vim.fn.getpid()

--- @class autocmd_event
--- @field id integer
--- @field event string
--- @field group number | nil
--- @field match string
--- @field buf number
--- @field file string
--- @field data any

--- @class typst_ts_match
--- @field [1]? {[1]: TSNode} call_ident
--- @field [2]? {[1]: TSNode} code
--- @field [3] {[1]: TSNode} block

--- @type { [integer]: boolean }
M._enabled_buffers = {}

local is_tmux = vim.env.TMUX ~= nil

--- Sets up the constant typst prelude string
local function setup_prelude()
  if M.config.styling_type == "colorscheme" then
    local color = M.config.color
    if (color == nil) then
      color = string.format('rgb("#%06X")', vim.api.nvim_get_hl(0, { name = "Normal" })["fg"])
    end
    -- FIXME: lists everything. agony. hope https://github.com/typst/typst/issues/3356 is resolved.
    M._styling_prelude = '' ..
        '#set page(width: auto, height: auto, margin: (x: 0pt, y: 0pt), fill: none)\n' ..
        '#set text(' .. color .. ', top-edge: "ascender", bottom-edge: "descender")\n' ..
        '#set line(stroke: ' .. color .. ')\n' ..
        '#set table(stroke: ' .. color .. ')\n' ..
        '#set circle(stroke: ' .. color .. ')\n' ..
        '#set ellipse(stroke: ' .. color .. ')\n' ..
        '#set line(stroke: ' .. color .. ')\n' ..
        '#set path(stroke: ' .. color .. ')\n' ..
        '#set polygon(stroke: ' .. color .. ')\n' ..
        '#set rect(stroke: ' .. color .. ')\n' ..
        '#set square(stroke: ' .. color .. ')\n' ..
        ''
  elseif M.config.styling_type == "simple" then
    M._styling_prelude = '' ..
        '#set page(width: auto, height: auto, margin: 0.75pt)\n' ..
        '#set text(top-edge: "ascender", bottom-edge: "descender")\n' ..
        ''
  elseif M.config.styling_type == "none" then
    M._styling_prelude = ''
  end
  --M._styling_prelude = M._styling_prelude .. "#let NVIM_TYPST_CONCEALER = true\n"
end

--- Takes in a value, and if it is nil, return the provided default
--- @generic T
--- @param val T?
--- @param default_val T
--- @return T
local function default(val, default_val)
  if val == nil then return default_val end
  return val
end

local ns_id = vim.api.nvim_create_namespace("typst-concealer")
-- used for each line of a multiline image
-- please tell me if you know of a better way of overlaying mulitline text
local ns_id2 = vim.api.nvim_create_namespace("typst-concealer-2")

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
---@return integer height
local function range_to_height(range)
  local start_row, end_row = range[1], range[3]
  return end_row - start_row + 1
end

-- Thanks https://github.com/3rd/image.nvim/issues/259 for showing how to do this with a code example!

--- @type { [integer]: integer[] | nil }
--- Goes from a text-less multiline ns_id mark to a list of one line ns_id2 marks for concealing
local multiline_marks = {}
--- @type { [integer]: integer }
local image_id_to_extmark = {}

--- Places the unicode characters to render a given image id over a range
--- @param image_id integer
--- @param range Range4
--- @param extmark_id? integer|nil
--- @param concealing? boolean should the text be concealing or non-concealing
--- @return integer
local function place_image_extmark(image_id, range, extmark_id, concealing)
  -- TODO: take bufnr
  local start_row, start_col, end_row, end_col = range[1], range[2], range[3], range[4]
  local height = range_to_height(range)
  --- @type integer
  local new_extmark_id = nil

  if height == 1 then
    if concealing == false then
      new_extmark_id = vim.api.nvim_buf_set_extmark(0, ns_id, start_row, start_col, {
        id = extmark_id,
        virt_lines = { { { "" } } },
        virt_text_pos = "overlay",
        invalidate = true,
        end_col = end_col,
        end_row = end_row
      })
    else
      new_extmark_id = vim.api.nvim_buf_set_extmark(0, ns_id, start_row, start_col, {
        id = extmark_id,
        virt_text = { { "" } },
        virt_text_pos = "inline",
        conceal = "",
        invalidate = true,
        end_col = end_col,
        end_row = end_row
      })
    end
  else
    if concealing == false then
      new_extmark_id = vim.api.nvim_buf_set_extmark(0, ns_id, start_row, start_col, {
        id = extmark_id,
        invalidate = true,
        virt_text = { { "" } },
        -- this is used for determining the virt_text_pos of the child ns_id2 extmarks
        -- this extmark will never actually have text
        virt_text_pos = "right_align",
        end_col = end_col,
        end_row = end_row
      })
    else
      new_extmark_id = vim.api.nvim_buf_set_extmark(0, ns_id, start_row, start_col, {
        id = extmark_id,
        invalidate = true,
        virt_text = { { "" } },
        -- this is used for determining the virt_text_pos of the child ns_id2 extmarks
        -- this extmark will never actually have text
        virt_text_pos = "overlay",
        end_col = end_col,
        end_row = end_row
      })
    end

    -- the extmarks will be added later
    multiline_marks[new_extmark_id] = {}
  end

  image_id_to_extmark[image_id] = new_extmark_id
  return new_extmark_id
end

--- Updates the text for an existing extmark
--- @param bufnr integer
--- @param extmark_id integer
--- @param string any
--- @param skip_hide_check? boolean | nil
local function update_extmark_text(bufnr, extmark_id, string, skip_hide_check)
  if (skip_hide_check ~= true) and Currently_hidden_extmark_ids[extmark_id] ~= nil then
    Currently_hidden_extmark_ids[extmark_id] = string
    return
  end
  local m = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_id, extmark_id, { details = true })
  if #m == 0 then
    -- The extmark is missing.
    -- This just means it was deleted at some point between creation and the image finishing rendering, which is bound to happen sometimes.
    -- This is okay, it just means we can't actually display text, not a catastrophic failure so we just fail quietly.
    return
  end
  --- @type integer, integer, vim.api.keyset.extmark_details
  local row, col, opts = m[1], m[2], m[3]

  local height = range_to_height({ row, col, opts.end_row, opts.end_col })
  if height ~= 1 then
    if multiline_marks[extmark_id] then
      for _, id in pairs(multiline_marks[extmark_id]) do
        vim.api.nvim_buf_del_extmark(bufnr, ns_id2, id)
      end
    end
    multiline_marks[extmark_id] = {}
    for i = 1, height do
      local lines = vim.api.nvim_buf_get_lines(0, row, opts.end_row + 1, false)
      -- ns_id2!
      local conceal = nil
      if opts.virt_text_pos ~= "right_align" then
        conceal = ""
      end
      local new_id = vim.api.nvim_buf_set_extmark(0, ns_id2, row + i - 1, 0, {
        virt_text = string[i],
        conceal = conceal,
        virt_text_pos = opts.virt_text_pos,
        end_col = #lines[i],
        end_row = row + i - 1
      })
      table.insert(multiline_marks[extmark_id], new_id)
    end
  elseif opts.virt_text_pos == "inline" then
    vim.api.nvim_buf_set_extmark(0, ns_id, row, col, {
      id = extmark_id,
      virt_text = string,
      virt_text_pos = opts.virt_text_pos,
      invalidate = opts.invalidate,
      end_col = opts.end_col,
      end_row = opts.end_row,
      --- @diagnostic disable-next-line nvim type is wrong
      conceal = "",
    })
  else
    vim.api.nvim_buf_set_extmark(0, ns_id, row, col, {
      id = extmark_id,
      virt_lines = { string },
      virt_text_pos = opts.virt_text_pos,
      invalidate = opts.invalidate,
      end_col = opts.end_col,
      end_row = opts.end_row,
      --- @diagnostic disable-next-line nvim type is wrong
      conceal = opts.conceal
    })
  end
end

--- Adds the concealing unicode characters to the relevant extmark(s) for the given image_id
--- @param bufnr integer
--- @param image_id integer
--- @param width integer
--- @param height integer
local function conceal_for_image_id(bufnr, image_id, width, height)
  local extmark_id = image_id_to_extmark[image_id]
  local multiline_extmark_ids = multiline_marks[extmark_id]

  local hl_group = "typst-concealer-image-id-" .. tostring(image_id)
  -- encode image_id into the foreground color
  vim.api.nvim_set_hl(0, hl_group, { fg = string.format("#%06X", image_id) })

  if multiline_extmark_ids == nil then
    local line = ""
    if width >= #(kitty_codes.diacritics) then
      line = "This image attempted to render wider than " ..
          #(kitty_codes.diacritics) .. " characters long. This is likely a bug."
    else
      for j = 0, width - 1 do
        line = line .. kitty_codes.placeholder .. kitty_codes.diacritics[1] .. kitty_codes.diacritics[j + 1]
      end
    end
    update_extmark_text(bufnr, extmark_id, { { line, hl_group } })
  else
    local lines = {}
    for i = 1, height do
      local line = ""
      if width >= #(kitty_codes.diacritics) then
        line = "This image attempted to render wider than " ..
            #(kitty_codes.diacritics) .. " characters long. This is likely a bug."
      elseif i >= #(kitty_codes.diacritics) then
        line = "This image attempted to render taller than " ..
            #(kitty_codes.diacritics) .. " lines. If you legitimately see this in a real document, open an issue."
      else
        for j = 0, width - 1 do
          line = line .. kitty_codes.placeholder .. kitty_codes.diacritics[i] .. kitty_codes.diacritics[j + 1]
        end
      end
      lines[#lines + 1] = { { line, hl_group } }
    end
    update_extmark_text(bufnr, extmark_id, lines)
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

--- Checks if parent_range contains child_range
---@param parent_range Range4
---@param child_range Range4
---@return boolean
local function range_contains(parent_range, child_range)
  local start_row1, start_col1, end_row1, end_col1 = parent_range[1], parent_range[2], parent_range[3], parent_range[4]
  local start_row2, start_col2, end_row2, end_col2 = child_range[1], child_range[2], child_range[3], child_range[4]
  if end_row1 > end_row2 or (end_row1 == end_row2 and end_col1 >= end_col2) then
    return true
  end
  return false
end

--- Tells terminal to read the image and link image id -> image
--- @param path string
--- @param image_id integer
--- @param width integer
--- @param height integer
local function create_image(path, image_id, width, height)
  path = vim.base64.encode(path)
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


--- Generates a filename for a given image id and buffer
--- @param id integer
--- @param bufnr integer
--- @return string
local function typst_file_path(id, bufnr)
  return "/tmp/tty-graphics-protocol-typst-concealer-" .. full_pid .. "-" .. bufnr .. "-" .. id .. ".png"
end

--- @type vim.Diagnostic[]
local diagnostics = {}
--- @type integer
local remaining_images = 0


--- @param status_code integer
--- @param stderr uv_pipe_t
--- @param original_range Range4 This range may be out of date by this point, but it is good enough for diagnostics
--- @param image_id integer
--- @param bufnr integer
--- @param extmark_id integer
--- @param is_live_preview boolean
local function on_typst_exit(status_code, stderr, original_range, image_id, bufnr, extmark_id, is_live_preview)
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



    local err = table.concat(err_bucket)
    local diagnostic = nil
    if status_code ~= 0 and err ~= "" then
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
        vim.api.nvim_buf_del_extmark(bufnr, ns_id, extmark_id)
        local ids = multiline_marks[extmark_id]
        if ids then
          for _, id in ipairs(ids) do
            vim.api.nvim_buf_del_extmark(bufnr, ns_id2, id)
          end
        end
      end)
    else
      local path = typst_file_path(image_id, bufnr)
      vim.schedule(function()
        local height = range_to_height(original_range)
        local success, data = pcall(pngData, path)
        if success == false then
          -- the image file doesn't exist (or is invalid in some way)
          -- this is likely just the tempfile being deleted by kitty
          -- because we've already deleted this image before it was rendered
          -- this is okay.
          return
        end

        -- Assumes a character has a 1/2 aspect ratio that needs accounting for
        local width = math.ceil((data.width / data.height) * 2) * height
        if width >= #(kitty_codes.diacritics) then
          width = #(kitty_codes.diacritics) - 1
        end

        create_image(path, image_id, width, height)
        conceal_for_image_id(bufnr, image_id, width, height)
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
--- @param image_id integer
--- @param orignal_range Range4 range which is safe to use for diagnostics only
--- @param str string typst text to render
--- @param extmark_id integer
--- @param prelude_count integer how far into the list of runtime_preludes should we add to the string
--- @param is_live_preview boolean
local function compile_image(bufnr, image_id, orignal_range, str, extmark_id, prelude_count, is_live_preview)
  -- TODO: use stdout maybe?
  local path = typst_file_path(image_id, bufnr)

  local stdin = vim.uv.new_pipe()
  local stdout = vim.uv.new_pipe()
  local stderr = vim.uv.new_pipe()

  local handle = vim.uv.spawn(M.config.typst_location, {
    stdio = { stdin, stdout, stderr },
    args = { "compile", "-", path, "--ppi=" .. M.config.ppi },
  }, function(code, signal)
    on_typst_exit(code, stderr, orignal_range, image_id, bufnr, extmark_id, is_live_preview)
  end)

  -- TODO: is this really the best way of doing this?
  local final_str = {}
  for i = 1, prelude_count, 1 do
    final_str[#final_str + 1] = runtime_preludes[i]
  end
  final_str[#final_str + 1] = M._styling_prelude
  final_str[#final_str + 1] = str
  stdin:write(final_str)
  stdin:close()
  stdout:close()
end

-- FIXME: this is bad. terrible even. fix it.
image_ids_in_use = {}
---@param bufnr integer
---@return integer
local function new_image_id(bufnr)
  for i = pid, 2 ^ 16 + pid - 1 do
    if image_ids_in_use[i] == nil then
      image_ids_in_use[i] = bufnr
      return i
    end
  end

  -- Image id table full, overflow it
  print([[
[typst-concealer] >65536 image ids in use, overflowing. This is probably a bug, you're looking at a very long document or a lot of documents.
Open an issue if you see this, the cap can be increased if someone actually needs it.
]])
  image_ids_in_use = {}
  -- as stated above, this is bad, i do not like it.
  return new_image_id(bufnr)
end

local function reset_buf(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id2, 0, -1)
  Live_preview_extmark_id = nil
  Currently_hidden_extmark_ids = {}
  multiline_marks = {}
  diagnostics = {}
  runtime_preludes = {}

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

runtime_preludes = {}

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
  local prev_range = nil

  for _, match, _ in M._typst_query:iter_matches(tree, bufnr, nil, nil, { all = true }) do
    --- @cast match typst_ts_match
    local block_type = match[3][1]:type()
    local start_row, start_col, end_row, end_col = match[3][1]:range()

    -- If the previous range contains this one, skip it
    -- This check should maybe have to interate through all the previous (and future) ranges
    -- but iter_matches goes in order so we're all good
    if prev_range ~= nil and range_contains(prev_range, { start_row, start_col, end_row, end_col }) then
      goto continue
    end

    if (block_type == "math") then
      local image_id = new_image_id(bufnr)
      remaining_images = remaining_images + 1
      ranges[image_id] = { { start_row, start_col, end_row, end_col }, #runtime_preludes }
      prev_range = { start_row, start_col, end_row, end_col }
    elseif (block_type == "code") then
      local code_type = match[2][1]:type()
      local call_ident = ""
      if match[1] ~= nil then
        local a, b, c, d = match[1][1]:range()
        call_ident = range_to_string({ a, b, c, d }, bufnr)
      end
      -- TODO: Consider special-casing other function calls, to deal with:
      -- #image, for larger images
      -- #link, for working links
      -- #highlight, for looking not terrible
      -- probably more too
      -- Special casing would not be useful for trying to render something as closely to how typst would
      -- but instead would be useful for those (me) using typst-concealer as the end goal
      -- Would def be toggleable though
      if (not vim.list_contains({ "let", "set", "import", "show" }, code_type)) and (not vim.list_contains({ "pagebreak" }, call_ident)) then
        local image_id = new_image_id(bufnr)
        remaining_images = remaining_images + 1
        ranges[image_id] = { { start_row, start_col, end_row, end_col }, #runtime_preludes }
        prev_range = { start_row, start_col, end_row, end_col }
      end

      if (vim.list_contains({ "let", "set", "import", "show" }, code_type)) then
        runtime_preludes[#runtime_preludes + 1] = range_to_string({ start_row, start_col, end_row, end_col }, bufnr) ..
            "\n"
      end
    end
    ::continue::
  end

  for id, image in pairs(ranges) do
    local range, prelude_count = image[1], image[2]
    local extmark_id = place_image_extmark(id, range)
    local str = range_to_string(range, bufnr)
    vim.schedule(function()
      compile_image(bufnr, id, range, str, extmark_id, prelude_count, false)
    end)
  end
  hide_extmarks_at_cursor()
end

--- @alias virt_text {[1]: string, [2]: string}[]

--- @type {[integer]: virt_text}
Currently_hidden_extmark_ids = {}

---@param bufnr integer
---@param id integer
---@param row integer
---@param col integer
---@param opts vim.api.keyset.extmark_details
---@param new_hidden table
---@param namespace_id integer
local function hide_extmark(bufnr, id, row, col, opts, new_hidden, namespace_id)
end

function hide_extmarks_at_cursor()
  local bufnr = vim.fn.bufnr()

  --- @type {[integer]: virt_text}
  local new_hidden = {}

  local mode = vim.api.nvim_get_mode().mode
  -- If we are not concealing in this mode, then don't do any hiding of extmarks
  if not (M.config.conceal_in_normal and mode:find('n', 1, true) ~= nil) then
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

    for _, extmark in ipairs(extmarks) do
      local id = extmark[1]
      if multiline_marks[id] ~= nil then
        if new_hidden[id] ~= nil then

        elseif Currently_hidden_extmark_ids[id] ~= nil then
          new_hidden[id] = Currently_hidden_extmark_ids[id]
          Currently_hidden_extmark_ids[id] = nil
        else
          if extmark[4].virt_text_pos == "right_align" then
            goto continue
          end
          local text = {}
          for _, new_id in ipairs(multiline_marks[id]) do
            local new_mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_id2, new_id, { details = true })
            --- @type vim.api.keyset.extmark_details
            local opts = new_mark[3]

            text[#text + 1] = opts.virt_text
            vim.api.nvim_buf_del_extmark(bufnr, ns_id2, new_id)
          end
          new_hidden[id] = text
          Currently_hidden_extmark_ids[id] = nil
        end
      else
        --- @type integer, integer, integer, vim.api.keyset.extmark_details
        local id, row, col, opts = extmark[1], extmark[2], extmark[3], extmark[4]
        if Currently_hidden_extmark_ids[id] ~= nil then
          new_hidden[id] = Currently_hidden_extmark_ids[id]
          Currently_hidden_extmark_ids[id] = nil
        else
          new_hidden[id] = opts.virt_text
          Currently_hidden_extmark_ids[id] = nil
          vim.api.nvim_buf_set_extmark(bufnr, ns_id, row, col, {
            id = id,
            virt_text = { { "" } },

            end_row = opts.end_row,
            end_col = opts.end_col,
            conceal = nil,
            virt_text_pos = opts.virt_text_pos,
            invalidate = opts.invalidate,
          })
        end
      end
      ::continue::
    end
  end

  -- show remaining extmarks not in selected lines
  for id, text in pairs(Currently_hidden_extmark_ids) do
    update_extmark_text(bufnr, id, text, true)
  end

  Currently_hidden_extmark_ids = new_hidden
end

local function get_typst_block_at_cursor()
  local parser = vim.treesitter.get_parser(0, "typst")
  local tree = parser:parse()[1]:root()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  cursor_pos = { cursor_pos[1] - 1, cursor_pos[2] }
  local element = tree:named_descendant_for_range(cursor_pos[1], cursor_pos[2], cursor_pos[3], cursor_pos[4])
  local outermost_block = nil
  while true do
    if element == nil then
      break
    end

    local type = element:type()
    if type == "math" or type == "code" then
      outermost_block = element
    elseif type == "ERROR" then
      -- if code block is contained within any sort of syntax error, just don't
      return nil
    end
    element = element:parent()
  end
  if outermost_block ~= nil then
    return outermost_block:range()
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
    if multiline_marks[preview_image.extmark_id] ~= nil then
      for _, id in pairs(multiline_marks[preview_image.extmark_id]) do
        vim.api.nvim_buf_del_extmark(bufnr, ns_id2, id)
      end
      multiline_marks[preview_image.extmark_id] = nil
    end

    preview_image = nil
  end
end

local function render_live_typst_preview()
  local bufnr = vim.fn.bufnr()
  local start_row, start_col, end_row, end_col = get_typst_block_at_cursor()
  if start_row == nil then
    clear_live_typst_preview(bufnr)
    return
  end
  local range = { start_row, start_col, end_row, end_col }
  local str = range_to_string(range, bufnr)
  local prev_extmark = nil
  if preview_image ~= nil then
    clear_image(preview_image.image_id)
    prev_extmark = preview_image.extmark_id
    if multiline_marks[prev_extmark] ~= nil then
      for _, id in pairs(multiline_marks[prev_extmark]) do
        vim.api.nvim_buf_del_extmark(bufnr, ns_id2, id)
      end
      multiline_marks[prev_extmark] = nil
    end
  end
  local new_preview = {}
  new_preview.image_id = new_image_id(bufnr)
  new_preview.extmark_id = place_image_extmark(new_preview.image_id, range, prev_extmark, false)
  -- TODO: determine prelude_count somehow?
  compile_image(bufnr, new_preview.image_id, range, str, new_preview.extmark_id, 0, true)
  preview_image = new_preview
end

--- @alias concealcursor_modes '' | 'n' | 'v' | 'nv' | 'i' | 'ni' | 'vi' | 'nvi' | 'c' | 'nc' | 'vc' | 'nvc' | 'ic' | 'nic' | 'vic' | 'nvic'

--- @class typstconfig
--- @field typst_location? string Where should typst-concealer look for your typst binary? Defaults to your PATH, likely does not need setting.
--- @field do_diagnostics? boolean Should typst-concealer provide diagnostics on error?
--- @field color? string What color should typst-concealer render text/stroke with? (only applies when styling_type is "colorscheme")
--- @field enabled_by_default? boolean Should typst-concealer conceal newly opened buffers by default?
--- @field styling_type? "none" | "simple" | "colorscheme" What kind of styling should typst-concealer apply to your typst?
--- @field ppi? integer What PPI should typst render at. Default is 300, typst's normal default is 144.
--- @field conceal_in_normal boolean Should typst-concealer still conceal when the normal mode cursor goes over a line.

local augroup = vim.api.nvim_create_augroup("typst-concealer", { clear = true })

--- Enable concealing for the given buffer
--- @param bufnr integer | nil
M.enable_buf = function(bufnr)
  if bufnr == nil then
    bufnr = vim.fn.bufnr()
  end
  M._enabled_buffers[bufnr] = true
  render_buf(bufnr)
end

--- Enable concealing for the given buffer
--- @param bufnr integer | nil
M.disable_buf = function(bufnr)
  if bufnr == nil then
    bufnr = vim.fn.bufnr()
  end
  M._enabled_buffers[bufnr] = nil
  render_buf(bufnr)
end

--- Toggle concealing for the given buffer
--- @param bufnr integer | nil
M.toggle_buf = function(bufnr)
  if bufnr == nil then
    bufnr = vim.fn.bufnr()
  end
  if M._enabled_buffers[bufnr] ~= nil then
    M._enabled_buffers[bufnr] = nil
  else
    M._enabled_buffers[bufnr] = true
  end
  render_buf(bufnr)
end

--- Re-render the conceals for the given buffer
--- @param bufnr integer | nil
M.rerender_buf = function(bufnr)
  if bufnr == nil then
    bufnr = vim.fn.bufnr()
  end
  render_buf(bufnr)
end

--- Initializes typst-concealer
--- @param cfg typstconfig
--- @see typstconfig
function M.setup(cfg)
  local version = vim.version()
  if version.major == 0 and version.minor < 10 then
    error("Typst concealer requires at least nvim 10.0 to work")
  end

  if M._setup_ran ~= nil then
    error("typst-concealer's setup function may only be run once")
  end
  M._setup_ran = true

  local config = {
    typst_location = default(cfg.typst_location, 'typst'),
    do_diagnostics = default(cfg.do_diagnostics, true),
    enabled_by_default = default(cfg.enabled_by_default, true),
    styling_type = default(cfg.styling_type, "colorscheme"),
    ppi = default(cfg.ppi, 300),
    --- @type string | nil
    color = cfg.color,
    conceal_in_normal = default(cfg.conceal_in_normal, false),
  }

  if not vim.list_contains({ "none", "simple", "colorscheme" }, config.styling_type) then
    error("typst styling_type" ..
      config.styling_type .. "is not a valid option. Please use 'none', 'simple' or 'colorscheme'")
  end

  M.config = config
  setup_prelude()

  if not config.allow_missing_typst and vim.fn.executable(M.config.typst_location) ~= 1 then
    if M.config.typst_location == "typst" then
      error("Typst executable not found in path, typst-concealer will not work")
    else
      error("Typst executable not found at '" .. M.config.typst_location .. "', typst-concealer will not work")
    end
  end

  local typst_parser_installed = pcall(vim.treesitter.get_parser, 0, "typst")
  if typst_parser_installed == false then
    error("Typst treesitter parser not found, typst-concealer will not work")
  end

  M._typst_query = vim.treesitter.query.parse("typst", [[
[
 (code
  [(_) (call item: (ident) @call_ident)] @code
 )
 (math)
] @block
]])

  local function init_buf(bufnr)
    vim.opt_local.conceallevel = 2
    vim.opt_local.concealcursor = "nv"

    if M.config.enabled_by_default then
      M._enabled_buffers[bufnr] = true
    end
  end


  if vim.v.vim_did_enter then
    local bufnr = vim.fn.bufnr()
    local str = vim.api.nvim_buf_get_name(bufnr)
    local match = str:match(".*%.typ$")
    if match ~= nil then
      init_buf(bufnr)
    end
  end


  vim.api.nvim_create_autocmd("BufEnter",
    {
      pattern = "*.typ",
      group = augroup,
      desc = "render file on enter",
      callback = function()
        render_buf()
      end
    })

  vim.api.nvim_create_autocmd({ "BufNew", "VimEnter" },
    {
      pattern = "*.typ",
      group = augroup,
      desc = "enable file on creation if the option is set",
      --- @param ev autocmd_event
      callback = function(ev)
        init_buf(ev.buf)
      end
    })

  vim.api.nvim_create_autocmd("BufWritePost",
    {
      pattern = "*.typ",
      group = augroup,
      desc = "render file on write",
      callback = function()
        vim.schedule(function()
          render_buf()
        end)
      end
    })

  vim.api.nvim_create_autocmd({ "CursorMovedI", "CursorMoved" },
    {
      pattern = "*.typ",
      group = augroup,
      desc = "unconceal on line hover",
      callback = function()
        hide_extmarks_at_cursor()
      end
    })

  vim.api.nvim_create_autocmd({ "ModeChanged" },
    {
      group = augroup,
      pattern = "v:*",
      desc = "unconceal when exiting visual mode, as this changes cursor pos without CursorMoved event",
      --- @param ev autocmd_event
      callback = function(ev)
        local str = vim.api.nvim_buf_get_name(ev.buf)
        local match = str:match(".*%.typ$")
        if match ~= nil then
          hide_extmarks_at_cursor()
        end
      end
    })

  vim.api.nvim_create_autocmd({ "ModeChanged" },
    {
      group = augroup,
      pattern = "i:*",
      desc = "remove preview when exiting insert mode",
      --- @param ev autocmd_event
      callback = function(ev)
        local str = vim.api.nvim_buf_get_name(ev.buf)
        local match = str:match(".*%.typ$")
        if match ~= nil then
          clear_live_typst_preview(ev.buf)
        end
      end
    })

  vim.api.nvim_create_autocmd("ModeChanged", {
    group = augroup,
    desc = "render live preview on insert enter",
    pattern = "*:i",
    --- @param ev autocmd_event
    callback = function(ev)
      local str = vim.api.nvim_buf_get_name(ev.buf)
      local match = str:match(".*%.typ$")
      if match ~= nil then
        render_live_typst_preview()
      end
    end
  })

  vim.api.nvim_create_autocmd("CursorMovedI",
    {
      pattern = "*.typ",
      group = augroup,
      desc = "render live preview on cursor move",
      callback = function()
        vim.schedule(function()
          render_live_typst_preview()
        end)
      end
    })

  if (cfg.color == nil) then
    vim.api.nvim_create_autocmd("ColorScheme",
      {
        group = augroup,
        desc = "update colour scheme",
        callback = function()
          setup_prelude()
          render_buf(vim.fn.bufnr())
        end
      })
  end

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "typst",
    callback = function(ev)
      init_buf(ev.buf)
    end
  })
end

return M
