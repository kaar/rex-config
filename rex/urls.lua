local terminal = "com.superlogical.terminal"
local scan_bytes = 128 * 1024
-- Rex measures blob_read's limit after JSON escaping, which expands VT output.
local blob_read_limit = 960 * 1024
local picker_limit = 2000
-- Rex does not expose the picker width. Leave room before the client clips.
local subtitle_limit = 52
-- Bytes of query or fragment to keep, so similar links can be told apart.
local suffix_room = 20
-- The directory of this file, used to find extract-urls.pl next to it.
local config_dir = assert(debug.getinfo(1, "S").source:match("^@?(.+/)"))
local extractor = config_dir .. "extract-urls.pl"

-- rex.block.call targets the focused block when no block_id is given.
local function recent_output()
  local snapshot = assert(rex.block.call(terminal, "format", {
    format = "vt",
    trim = true,
    unwrap = true,
    max_bytes = scan_bytes,
  }))
  if not snapshot.id then return snapshot.content end

  -- Seek to the end of large captures instead of reading all of scrollback.
  local offset = math.max(0, snapshot.total - scan_bytes)
  local tail = assert(rex.block.call(terminal, "blob_read", {
    id = snapshot.id,
    offset = offset,
    max_bytes = blob_read_limit,
  }))
  assert(tail.eof, "Could not read the end of the terminal output.")
  if offset == 0 then return tail.data end

  -- The byte limit can cut a line in two. Do not extract links from that line.
  local newline = tail.data:find("\n", 1, true)
  return newline and tail.data:sub(newline + 1) or ""
end

-- Lengths count bytes. Visible URLs are ASCII; rare OSC 8 targets may not be.
local function url_item(url)
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

rex.action{
  name = "open_url",
  title = "Open URL from Scrollback…",
  description = "Search for web links in the focused terminal pane.",
  args = {},
  run = function(ctx)
    assert(ctx.block_id, "Focus a terminal pane first.")
    local urls = assert(rex.exec({ "/usr/bin/perl", extractor }, {
      stdin = recent_output(),
    }))
    assert(urls.ok, "Could not extract URLs: " .. urls.stderr)

    -- The extractor prints every occurrence oldest first. Show the newest
    -- occurrence of each target first.
    local found = {}
    for url in urls.stdout:gmatch("[^\n]+") do
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
    if #items == 0 then return end

    local url, reason, detail = rex.ui.pick{
      title = "Open URL",
      placeholder = "Filter links",
      items = items,
    }
    if not url then
      if reason == "cancelled" then return end
      error("Could not pick a URL: " .. (detail or reason), 0)
    end

    local opened = assert(rex.exec({ "/usr/bin/open", "-u", url }))
    assert(opened.ok, "Could not open the URL: " .. opened.stderr)
  end,
}
