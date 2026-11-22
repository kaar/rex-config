require("projects")
require("scrollback")
require("urls")

rex.bind("cmd+o", "open_project")
rex.bind("ctrl+space>f", "open_project")
rex.bind("cmd+e", "open_scrollback")
rex.bind("cmd+u", "open_url")

rex.bind("cmd+/", "client.sidebar.toggle")
rex.bind("cmd+b", "client.sidebar.toggle")

-- splits (-, |)
rex.bind("ctrl+space>-", "pane.split", { direction = "down" })
rex.bind("ctrl+space>shift+\\", "pane.split", { direction = "right" })

-- move pane to a new tab (!)
rex.bind("ctrl+space>shift+1", "pane.move_to_new_tab")

-- tab navigation
rex.bind("alt+j", "client.tab.next")
rex.bind("alt+k", "client.tab.previous")

-- pane focus
rex.bind("ctrl+h", "pane.focus", { direction = "left" })
rex.bind("ctrl+j", "pane.focus", { direction = "down" })
rex.bind("ctrl+k", "pane.focus", { direction = "up" })
rex.bind("ctrl+l", "pane.focus", { direction = "right" })
