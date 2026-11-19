local function sessions_by_label()
  local result = assert(rex.call("session.list"))
  local sessions = {}
  for _, session in ipairs(result.sessions or {}) do
    local label = session.label
    if sessions[label] == nil then
      sessions[label] = session.session_id
    else
      sessions[label] = false -- The label matches more than one session.
    end
  end
  return sessions
end

rex.action{
  name = "open_project",
  title = "Open Project…",
  description = "Switch to a project session or create one in its directory.",
  args = {},
  run = function()
    local root = os.getenv("DEV")
    if not root or root == "" then
      root = assert(os.getenv("HOME"), "Set DEV or HOME on the Rex server.") .. "/Dev"
    end
    assert(root:sub(1, 1) == "/", "Set DEV to an absolute path on the Rex server.")

    local dirs = assert(rex.exec({
      "/usr/bin/find", "-L", root, "-mindepth", "1", "-maxdepth", "1", "-type", "d", "-print0",
    }))
    assert(dirs.ok, "Could not list projects in " .. root .. ": " .. dirs.stderr)

    local sessions = sessions_by_label()
    local items = {}
    for path in dirs.stdout:gmatch("([^%z]+)%z") do
      local name = path:match("[^/]+$")
      local session = sessions[name]
      items[#items + 1] = {
        id = path,
        title = name,
        icon = "folder",
        detail = session == false and "Duplicate labels" or (session and "Open session" or "New session"),
      }
    end
    assert(#items > 0, "No project directories found in " .. root)
    table.sort(items, function(a, b) return a.title < b.title end)

    local path, reason, detail = rex.ui.pick{ title = "Open Project", items = items }
    if not path then
      if reason == "cancelled" then return end
      error("Could not pick a project: " .. (detail or reason), 0)
    end

    local name = path:match("[^/]+$")
    -- The session list can change while the picker is open.
    local id = sessions_by_label()[name]
    if id == false then
      error("More than one session is named " .. name .. ". Rename one and try again.", 0)
    end
    if not id then
      local created = assert(rex.call("session.create", {
        label = name,
        initial_windows = {{
          window_label = "Terminal",
          layout = rex.layout.block{
            flavor = "com.superlogical.terminal.shell",
            options = { cwd = path },
          },
        }},
      }))
      id = created.session_id
    end

    rex.client.queue("session.select", { session_id = id })
  end,
}
