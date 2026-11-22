local terminal = require("terminal")
local perl = require("perl")

-- Lengths count bytes. Visible URLs are ASCII; rare OSC 8 targets may not be.
local function url_item(url)
  -- Bytes of query or fragment to keep, so similar links can be told apart.
  local suffix_room = 20
  -- Rex does not expose the picker width. Leave room before the client clips.
  local subtitle_limit = 52
  local origin, path, suffix = url:match("^(%a+://[^/?#]*)([^?#]*)(.*)$")
  local leaf = path:match("^.*/([^/]+/*)$")
  local subtitle = url
  if #url > subtitle_limit then
    -- Drop middle path segments if needed, so the start of the query or
    -- fragment still fits.
    local base = origin .. path
    local room = math.min(#suffix, suffix_room)
    if leaf and #base + room > subtitle_limit - #"…" then
      local short = origin .. "/…/" .. leaf
      if #short < #base then base = short end
    end
    subtitle = base .. suffix
    if #subtitle > subtitle_limit then
      subtitle = subtitle:sub(1, subtitle_limit - #"…") .. "…"
    end
  end
  return { id = url, title = leaf or origin .. path, subtitle = subtitle }
end

local function build_url_items(urls)
  local picker_limit = 2000
  local found = {}
  for url in urls:gmatch("[^\n]+") do
    found[#found + 1] = url
  end
  local items, seen = {}, {}
  for i = #found, 1, -1 do
    local url = found[i]
    if not seen[url] then
      seen[url] = true
      items[#items + 1] = url_item(url)
      if #items == picker_limit then break end
    end
  end
  return items
end

local function open_url(url)
  local opened = assert(rex.exec({ "/usr/bin/open", "-u", url }))
  assert(opened.ok, "Could not open the URL: " .. opened.stderr)
end

local function run_open_url(ctx)
  local block_id = assert(ctx.block_id, "Focus a terminal pane first.")
  local items = build_url_items(perl.extract_urls(terminal.recent_output(block_id, "vt")))
  if #items == 0 then return end

  local url, reason, detail = rex.ui.pick {
    title = "Open URL",
    placeholder = "Filter links",
    items = items,
  }
  if not url then
    if reason == "cancelled" then return end
    error("Could not pick a URL: " .. (detail or reason), 0)
  end

  open_url(url)
end

rex.action {
  name = "open_url",
  title = "Open URL from Scrollback…",
  description = "Search for web links in the focused terminal pane.",
  args = {},
  run = run_open_url,
}
