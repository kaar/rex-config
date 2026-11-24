local function run_toggle_recent_session(ctx)
  if not ctx.session_id then return end

  -- Start from the latest focus each time. Reversing also records the new focus.
  local target = assert(rex.call("focus_history.reverse", {
    not_session_id = ctx.session_id,
  }))
  if not target.reversed then return end

  rex.client.queue("session.select", {
    session_id = target.session_id,
    window_id = target.window_id,
  })
end

rex.action {
  name = "toggle_recent_session",
  title = "Toggle Recent Session",
  description = "Switch to the last session you used. Run again to return.",
  args = {},
  run = run_toggle_recent_session,
}
