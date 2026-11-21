# Rex shortcuts and links

This guide covers the shortcuts in [`rex/init.lua`](rex/init.lua) and the built-in shortcuts for Rex on macOS. A session holds tabs. A tab holds one or more panes. A pane is one terminal area.

`Prefix` means `Ctrl+Space`. For `Prefix → v`, press `Ctrl+Space`, release both keys, then press `v`. Press `Esc` to cancel a sequence. `Option` is `alt` in the configuration.

## Panes

| Action | This setup | Built-in macOS shortcut |
| --- | --- | --- |
| Focus the pane to the left, down, up, or right | `Ctrl+h/j/k/l`, `Option+h/j/k/l`, or `Prefix → h/j/k/l` | `Cmd+Option+Arrow` |
| Cycle to the next or previous pane | | `Cmd+]` / `Cmd+[` |
| Open a pane to the right | `Prefix → v` or `Prefix → Shift+Backslash` | `Cmd+D` |
| Open a pane below | `Prefix → -` | `Cmd+Shift+D` |
| Open a pane on any side | | `Cmd+Shift+Arrow` |
| Let Rex choose the split direction | | `Cmd+Return` |
| Move the focused pane in a direction | | `Cmd+Option+Shift+Arrow` |
| Maximize the focused pane or restore the layout | | `Cmd+Shift+Return` |
| Close the focused pane | | `Cmd+W` |

Rex handles `Ctrl+h/j/k/l` before terminal programs do. These keys switch Rex panes, not splits inside Neovim.

To resize once, press `Prefix`, then `Shift+h/j/k/l`. The directions are left, down, up, and right. To resize several times, press `Prefix → r` once, then repeat the shifted direction keys. Press `Return` or `Esc` to exit. Other keys do not reach the terminal in this mode.

If a terminal program needs `Ctrl+Space`, press `Prefix → Ctrl+Space` to send it one copy of the key.

## Tabs

| Action | This setup | Built-in macOS shortcut |
| --- | --- | --- |
| Create a tab | | `Cmd+T` |
| Go to the next tab | `Prefix → n` | `Ctrl+Tab` or `Cmd+Shift+]` |
| Go to the previous tab | `Prefix → p` | `Ctrl+Shift+Tab` or `Cmd+Shift+[` |
| Go to a tab by number | `Option+1` through `Option+9` | `Cmd+1` through `Cmd+9` |
| Rename the current tab | `Prefix → ,` or `Prefix → Shift+t` | |
| Move the current tab earlier or later | | `Ctrl+Shift+Page Up` / `Ctrl+Shift+Page Down` |
| Close the entire current tab | `Prefix → Shift+x` or `Prefix → Shift+7` | `Cmd+Option+W` |

Closing a tab closes all its panes. Use `Cmd+W` if you only want to close the focused pane.

## Sessions, commands, and terminal output

| Action | Built-in macOS shortcut |
| --- | --- |
| Open a new Rex window | `Cmd+N` |
| Create a session | `Cmd+Shift+N` |
| Pick a session | `Cmd+K` |
| Jump to a pane, tab, or session with Go to Anything | `Cmd+P` |
| Search Rex actions in the command palette | `Cmd+Shift+P` |
| Show or hide the sidebar | `Cmd+/` |
| Find text in the terminal | `Cmd+F` (moved to `Cmd+Option+F` in this setup) |
| Go to the next or previous match while Find is open | `Cmd+G` / `Cmd+Shift+G` |
| Start Copy Mode to select text with the keyboard | `Cmd+Shift+C` |
| Increase, decrease, or reset text size | `Cmd+=` / `Cmd+-` / `Cmd+0` |

Press `Cmd+F` to open the project picker. Rex switches to the existing session if the project is already open. Otherwise, Rex creates a session at the project root.

In Copy Mode, move with the arrow keys or `h/j/k/l`. Press `v` to start a selection, then move to select more text. Press `y` or `Return` to copy it. Press `Esc` or `q` to leave Copy Mode.

For actions without a shortcut, open the command palette and search by name. For example, use “Balance Splits” to even out pane sizes or “Move Pane to Tab…” to move a pane to another tab.

## Open URLs

- To open a recognized link on screen, hold `Cmd` and click the link.
- To preview links on screen in the focused pane, press `Cmd+Y` for Quick Look. Quick Look does not search older terminal output.
- If you already know the address, run `open 'https://example.com'` in a local macOS shell.

### Pick a URL from older output

Rex Quick Look does not replace [`herdr-fzf-url`](https://github.com/kaar/herdr-fzf-url). The Herdr plugin uses `Prefix → u` if you bind it as shown in its README. It searches scrollback, which is terminal output above the screen. This Rex configuration has no `Prefix → u` binding.

For a similar search in Rex on your Mac, reuse the `extract-urls` helper from the plugin. Run this in the local Rex pane that contains the output. It needs `fzf`, `perl`, and the checkout at `~/Dev/herdr-fzf-url/`.

```sh
if url=$(
  rex capture -s "$REX_SESSION" -b "$REX_BLOCK" --trim --unwrap |
    tail -n 2000 |
    perl "$HOME/Dev/herdr-fzf-url/extract-urls" |
    grep -E '^https?://' |
    tail -r |
    fzf --no-multi --prompt='Open URL> '
); then
  open "$url"
fi
```

Type part of the address, then press `Return` to open it or `Esc` to cancel. This command opens one web link at a time. It sees addresses in the captured text, not destinations hidden behind link labels.

## Look up or change shortcuts

Run `rex keymap` to list the shortcuts Rex loaded from `init.lua`. It does not list built-in shortcuts or overrides set in the app. Shortcuts set in the app take priority over `init.lua`.

After editing `init.lua`, run `rex config reload` or choose Reload Config in the command palette. For the full list of built-in shortcuts, see the [Rex Mac actions reference](https://www.superlogical.com/rex/docs/reference/mac-actions).
