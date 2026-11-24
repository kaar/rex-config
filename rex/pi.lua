local terminal = require("terminal")

rex.action {
  name = "open_pi_split",
  title = "Open Pi in Split Pane",
  run = function(ctx)
    local block_id = assert(ctx.block_id, "Focus a terminal pane first.")
    local cwd = assert(terminal.working_directory(block_id), "Could not determine the working directory.")
    local size = assert(rex.block.call("com.superlogical.terminal", "size", { block_id = block_id }))
    local width = size.columns * size.cell_width_px
    local height = size.rows * size.cell_height_px

    return assert(rex.session.new_split {
      anchor_id = block_id,
      direction = width > height and "horizontal" or "vertical",
      side = "after",
      focus = true,
      layout = rex.layout.block {
        label = "Pi",
        flavor = "com.superlogical.terminal.shell",
        options = { cwd = cwd, interactive = true, command = { "pi" } },
      },
    })
  end,
}
