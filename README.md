# rex-config

My [Rex](https://www.superlogical.com/rex/docs) configuration for macOS. It adds shortcuts for working with panes and tabs, opening project sessions, and searching terminal output.

## Install

This setup uses the default Rex configuration directory, `~/.config/rex`. If the server runs with `XDG_CONFIG_HOME` or `REX_CONFIG` set, see the [configuration guide](docs/customize/config.md).

If `~/.config/rex` already exists, move it to a backup location. Link the entire [`rex/`](rex/) directory so that Rex can load the files next to [`init.lua`](rex/init.lua). Run these commands from the repository root:

```sh
mkdir -p "$HOME/.config"
test ! -e "$HOME/.config/rex" && test ! -L "$HOME/.config/rex" && ln -s "$PWD/rex" "$HOME/.config/rex"
```

Choose **Reload Config** in Rex after installation or after you edit the configuration. To use the Neovim actions, make sure that `nvim` is on your login shell’s `PATH`.

## Rex extensions

[`rex/init.lua`](rex/init.lua) loads these custom actions. You can also find them in the Rex command palette:

- [Open Project](rex/projects.lua): Switch to a project session or start one in the selected directory.
- [Toggle Recent Session](rex/sessions.lua): Switch between the last two sessions on the same Rex server.
- [Open Pi in New Tab](rex/pi.lua): Start Pi in a new tab in the focused pane’s working directory.
- [Open Scrollback in Neovim](rex/scrollback.lua): View the focused pane’s saved terminal output in read-only mode.
- [Open URL from Scrollback](rex/urls.lua): Pick a web link from recent terminal output and open it in the default browser.
- [Open File from Scrollback](rex/files.lua): Pick a file from recent terminal output and open it in Neovim.

The configuration also supports [Neovim navigation](#neovim-navigation) through the optional `rex-navigator.nvim` plugin.

## Shortcuts

| Shortcut | Action |
| --- | --- |
| Cmd+O, Cmd+Shift+F, or Ctrl+Space then F | Open the project picker. |
| Cmd+K or Cmd+F | Open Change Session. |
| Cmd+Shift+K | Toggle between the last two sessions on the same Rex server. |
| Cmd+/ | Open Find to search terminal output. |
| Cmd+B | Show or hide the sidebar. |
| Ctrl+Cmd+Enter | Start Pi in the focused pane’s working directory. Split right or down based on the pane’s size, then focus Pi. |
| Cmd+E | Open the focused pane’s scrollback (saved terminal output) in a read-only Neovim pane. |
| Cmd+U | Pick a web link from recent output and open it in the default browser. |
| Cmd+Shift+U | Pick a text file from recent output and open it in a floating Neovim pane. |

Both pickers use the focused pane. The link picker accepts only HTTP and HTTPS. The file picker accepts local `file://` links and uses line numbers from references such as `src/main.lua:42`. Cmd+Shift+U replaces the default shortcut for **Install Update**, which remains in the app menu.

Run `rex keymap` in a Rex terminal for the full list of shortcuts that the running server loaded from this configuration. The output shows each action and its source file and line. It does not include built-in shortcuts or shortcuts set in the app.

## Project sessions

The project picker lists directories one level below `DEV`, including links to directories. Set `DEV` to an absolute path in the Rex server’s environment. If `DEV` is unset or empty, the picker uses `~/Dev`.

If one session has the same name as the directory, Rex switches to it. If none match, Rex starts a session with one terminal tab in the project directory. If several sessions match, rename them so that only one matches.

## Neovim navigation

If you install `rex-navigator.nvim`, this configuration loads it to move focus between Neovim splits and Rex panes. It looks for the plugin under `nvim/site/pack/core/opt/rex-navigator.nvim` in `XDG_DATA_HOME` or, by default, `~/.local/share`. If Rex cannot load the plugin, it logs a warning and loads the rest of the configuration.

## Rex documentation

Read the [local documentation index](docs/README.md) or search the local copy with `rg --no-ignore -n 'term' docs/`. The repository tracks this copy, but the script replaces it on each refresh. Do not edit it by hand.

To refresh the copy from the [official Rex documentation](https://www.superlogical.com/rex/docs), run this command from the repository root. The script requires Python 3 and no extra packages.

```sh
python3 scripts/sync-rex-docs.py
```
