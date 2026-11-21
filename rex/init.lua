require("projects")
require("scrollback")

rex.bind("cmd+o", "open_project")
rex.bind("ctrl+space>f", "open_project")
rex.bind("cmd+e", "open_scrollback")

-- splits (-, |)
rex.bind("ctrl+space>-", "pane.split", { direction = "down" })
rex.bind("ctrl+space>shift+\\", "pane.split", { direction = "right" })

-- tab navigation
rex.bind("alt+j", "client.tab.next")
rex.bind("alt+k", "client.tab.previous")

-- pane focus
rex.bind("ctrl+h", "pane.focus", { direction = "left" })
rex.bind("ctrl+j", "pane.focus", { direction = "down" })
rex.bind("ctrl+k", "pane.focus", { direction = "up" })
rex.bind("ctrl+l", "pane.focus", { direction = "right" })
