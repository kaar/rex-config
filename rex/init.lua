require("projects")
require("scrollback")
require("urls")
require("files")
require("sessions")
require("pi")

rex.bind("cmd+o", "open_project")
rex.bind("cmd+shift+f", "open_project")
rex.bind("ctrl+space>f", "open_project")
-- Add Cmd+F for Change Session without removing the default Cmd+K.
rex.bind("cmd+f", "session.switch")
rex.bind("cmd+shift+k", "toggle_recent_session")
rex.bind("cmd+e", "open_scrollback")
rex.bind("cmd+u", "open_url")
-- Replaces the default Install Update (client.update.accept) binding. Install
-- Update stays available in the app menu.
rex.bind("cmd+shift+u", "open_file")

rex.bind("cmd+/", "client.find.open")
rex.bind("cmd+b", "client.sidebar.toggle")

-- splits (-, |)
rex.bind("ctrl+space>-", "pane.split", { direction = "down" })
rex.bind("ctrl+space>shift+\\", "pane.split", { direction = "right" })

-- move pane to a new tab (!)
rex.bind("ctrl+space>shift+1", "pane.move_to_new_tab")

rex.bind("ctrl+cmd+enter", "open_pi_split")

-- tab navigation
rex.bind("alt+j", "client.tab.next")
rex.bind("alt+k", "client.tab.previous")

-- Navigate between Neovim splits and Rex panes.
local ok, err = pcall(function()
  local data = os.getenv("XDG_DATA_HOME")
  if not data or data == "" then
    data = os.getenv("HOME") .. "/.local/share"
  end
  dofile(data .. "/nvim/site/pack/core/opt/rex-navigator.nvim/rex/rex-navigator.lua").setup()
end)
if not ok then
  rex.log("warn", "rex-navigator not loaded: " .. tostring(err))
end
