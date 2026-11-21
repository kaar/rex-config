rex.action{
  name = "open_scrollback",
  title = "Open Scrollback in Neovim",
  run = function(ctx)
    local block = assert(ctx.block_id, "Focus a terminal pane first.")
    local source = assert(rex.session.describe_block{ block_id = block })
    assert(rex.session.new_layer{
      window_id = assert(source.block.window_id, "The terminal pane must be in a tab."),
      bounds = { 0.1, 0.1, 0.8, 0.8 },
      focus = true,
      layout = rex.layout.block{
        label = "Scrollback",
        flavor = "com.superlogical.terminal.shell",
        options = {
          shell = "none",
          command = {
            "/bin/zsh", "-lc",
            [[nvim -R -n +'normal! G' =(rex capture --trim --unwrap -b "$1")]],
            "rex-scrollback", block,
          },
        },
      },
    })
  end,
}
