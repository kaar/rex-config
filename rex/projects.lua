-- How a project directory relates to the open sessions, in picker order.
local states = {
  open      = { rank = 1, icon = "terminal", detail = "Open session" },
  new       = { rank = 2, icon = "folder",   detail = "New session" },
  duplicate = { rank = 3, icon = "terminal", detail = "Duplicate labels" },
}

local function basename(path)
  return path:match("[^/]+$")
end

-- Maps each label to its session ID, or to false when the label matches more
-- than one session.
local function sessions_by_label()
  local result = assert(rex.call("session.list"))
  local sessions = {}
  for _, session in ipairs(result.sessions or {}) do
    local label = session.label
    if sessions[label] == nil then
      sessions[label] = session.session_id
    else
      sessions[label] = false
    end
  end
  return sessions
end

local function session_state(session)
  if session == false then return states.duplicate end
  return session and states.open or states.new
end

local function project_root()
  local root = os.getenv("DEV")
  if not root or root == "" then
    root = assert(os.getenv("HOME"), "Set DEV or HOME on the Rex server.") .. "/Dev"
  end
  assert(root:sub(1, 1) == "/", "Set DEV to an absolute path on the Rex server.")
  return root
end

local function list_project_dirs(root)
  local dirs = assert(rex.exec({
    "/usr/bin/find", "-L", root, "-mindepth", "1", "-maxdepth", "1", "-type", "d", "!", "-name", ".git", "-print0",
  }))
  assert(dirs.ok, "Could not list projects in " .. root .. ": " .. dirs.stderr)

  local paths = {}
  for path in dirs.stdout:gmatch("([^%z]+)%z") do
    paths[#paths + 1] = path
  end
  assert(#paths > 0, "No project directories found in " .. root)
  return paths
end

local function create_session(name, path)
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
  return created.session_id
end

rex.action{
  name = "open_project",
  title = "Open Project…",
  description = "Switch to a project session or create one in its directory.",
  args = {},
  run = function()
    local sessions = sessions_by_label()
    local projects = {}
    for _, path in ipairs(list_project_dirs(project_root())) do
      local name = basename(path)
      projects[#projects + 1] = { path = path, name = name, state = session_state(sessions[name]) }
    end

    table.sort(projects, function(a, b)
      if a.state.rank ~= b.state.rank then return a.state.rank < b.state.rank end
      return a.name < b.name
    end)

    local items = {}
    for i, project in ipairs(projects) do
      items[i] = {
        id = project.path,
        title = project.name,
        icon = project.state.icon,
        detail = project.state.detail,
      }
    end

    local path, reason, detail = rex.ui.pick{ title = "Open Project", items = items }
    if not path then
      if reason == "cancelled" then return end
      error("Could not pick a project: " .. (detail or reason), 0)
    end

    local name = basename(path)
    -- The session list can change while the picker is open.
    local id = sessions_by_label()[name]
    if id == false then
      error("More than one session is named " .. name .. ". Rename one and try again.", 0)
    end

    rex.client.queue("session.select", { session_id = id or create_session(name, path) })
  end,
}
