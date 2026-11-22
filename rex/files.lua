local terminal = require("terminal")
local perl = require("perl")

-- Make the path absolute without collapsing components. In particular, ..
-- after a symlink must be resolved by the filesystem.
local function resolve(path, cwd, home)
  if path:sub(1, 1) == "/" then return path end
  local base = cwd
  if path:sub(1, 2) == "~/" then
    base, path = home, path:sub(3)
  end
  if not base then return end
  return base .. (base:sub(-1) == "/" and "" or "/") .. path
end

-- Lengths count bytes. Paths from file:// URLs may be non-ASCII.
local function file_item(id, file, home)
  -- Rex does not expose the picker width. Leave room before the client clips.
  local subtitle_limit = 52
  local title = file.path:match("([^/]+)$") .. (file.line and ":" .. file.line or "")
  local subtitle = file.path
  if home and subtitle:sub(1, #home + 1) == home .. "/" then
    subtitle = "~" .. subtitle:sub(#home + 1)
  end
  if #subtitle > subtitle_limit then
    -- Keep the end of the path, starting at a whole UTF-8 character.
    local tail = subtitle:sub(-(subtitle_limit - #"…"))
    subtitle = "…" .. tail:gsub("^[\128-\191]+", "")
  end
  return { id = id, title = title, subtitle = subtitle }
end

local function build_file_items(refs, cwd)
  local home = os.getenv("HOME")
  local check_limit, picker_limit = 500, 10

  local refs_in_order = {}
  for path, line in refs:gmatch("([^\t\n]+)\t?(%d*)\n") do
    refs_in_order[#refs_in_order + 1] = { path = path, line = line }
  end

  -- The extractor emits oldest first. Keep only the newest reference per path.
  local paths, latest = {}, {}
  for i = #refs_in_order, 1, -1 do
    local ref = refs_in_order[i]
    local path = resolve(ref.path, cwd, home)
    if path and not latest[path] then
      paths[#paths + 1] = path
      latest[path] = { path = path, line = ref.line ~= "" and ref.line or nil }
      if #paths == check_limit then break end
    end
  end

  local valid = perl.text_files(paths)
  local items, files = {}, {}
  for _, path in ipairs(paths) do
    if valid[path] then
      local id = tostring(#items + 1)
      files[id] = latest[path]
      items[#items + 1] = file_item(id, latest[path], home)
      if #items == picker_limit then break end
    end
  end
  return items, files
end

local function originating_endpoint()
  local status = assert(rex.call("server.status"))
  local listeners = assert(status.listeners, "The Rex server did not report its listeners.")
  for _, listener in ipairs(listeners) do
    if listener.primary then
      return assert(listener.endpoint, "The Rex server's primary listener has no endpoint.")
    end
  end
  error("Could not determine the originating Rex server's endpoint.", 0)
end

local function create_layer_after_picker(layer)
  -- Rex restores focus to the original pane when the picker closes.
  -- Delay layer creation so the new pane can keep focus.
  local endpoint = originating_endpoint()
  return rex.exec.start({
    "/bin/zsh", "-c",
    [[
      /bin/sleep 0.25 || exit $?
      cli="$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"
      output=$("$cli" --autostart=false --server "$1" api call session.new_layer "$2" 2>&1) && exit 0
      exit_code=$?
      /usr/bin/logger -t rex-open-layer "session.new_layer failed (exit $exit_code): $output"
      /usr/bin/osascript -e 'display notification "Could not open the floating pane. See Console for details." with title "Rex"'
      exit "$exit_code"
    ]],
    "rex-open-layer", endpoint, assert(rex.json.encode(layer)),
  }, { detach = true, stdout = false, stderr = false })
end

local function open_file_in_layer(ctx, block_id, file)
  -- The login shell finds nvim on PATH. File data stays in arguments.
  local command = { "/bin/zsh", "-lc", [[exec nvim "$@"]], "rex-open-file" }
  if file.line then
    command[#command + 1] = "+" .. file.line
  end
  command[#command + 1] = "--"
  command[#command + 1] = file.path

  local source = assert(rex.session.describe_block { block_id = block_id })
  local window_id = assert(source.block.window_id, "The terminal pane must be in a tab.")

  return create_layer_after_picker {
    session_id = ctx.session_id,
    window_id = window_id,
    bounds = { 0.1, 0.1, 0.8, 0.8 },
    focus = true,
    layout = rex.layout.block {
      label = file.path:match("([^/]+)$"),
      flavor = "com.superlogical.terminal.shell",
      options = { shell = "none", command = command },
    },
  }
end

local function run_open_file(ctx)
  local block_id = assert(ctx.block_id, "Focus a terminal pane first.")
  local cwd = terminal.working_directory(block_id)

  local refs = perl.extract_links(terminal.recent_output(block_id, "text"))

  local items, files = build_file_items(refs, cwd)
  if #items == 0 then return end

  local id, reason, detail = rex.ui.pick {
    title = "Open File",
    placeholder = "Filter files",
    items = items,
  }
  if not id then
    if reason == "cancelled" then return end
    error("Could not pick a file: " .. (detail or reason), 0)
  end
  local file = files[id]

  -- The file can disappear or change while the picker is open.
  if not perl.text_files({ file.path })[file.path] then
    error("The file no longer exists or is not a text file: " .. file.path, 0)
  end

  local started, err = open_file_in_layer(ctx, block_id, file)
  if not started then error("Could not start the floating Neovim pane: " .. err, 0) end
end

rex.action {
  name = "open_file",
  title = "Open File from Scrollback…",
  description = "Search for file references in the focused terminal pane and open one in Neovim.",
  args = {},
  run = run_open_file,
}
