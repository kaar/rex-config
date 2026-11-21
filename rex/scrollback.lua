rex.action{
  name = "open_scrollback",
  title = "Open Scrollback in Neovim",
  description = "Open the focused terminal pane's scrollback read-only in Neovim.",
  args = {},
  run = function(ctx)
    local block_id = assert(ctx.block_id, "Focus a terminal pane first.")
    local source = assert(rex.session.describe_block{ block_id = block_id })
    local window_id = assert(source.block.window_id, "The terminal pane must be in a tab.")
    assert(rex.session.new_layer{
      window_id = window_id,
      bounds = { 0.1, 0.1, 0.8, 0.8 },
      focus = true,
      layout = rex.layout.block{
        label = "Scrollback",
        flavor = "com.superlogical.terminal.shell",
        options = {
          shell = "none",
          -- zsh's =(...) writes the capture to a temporary file for nvim. The
          -- login shell provides the PATH that finds nvim and rex.
          command = {
            "/bin/zsh", "-lc",
            [[nvim -R -n +'normal! G' =(rex capture --trim --unwrap -b "$1")]],
            "rex-scrollback", block_id,
          },
        },
      },
    })
  end,
}
