# rex-config

Keyboard shortcuts for Rex, my terminal multiplexer.

See [Rex shortcuts and links](SHORTCUTS.md) for the keys in this setup and how to open URLs.

## Install

If `~/.config/rex` exists, move it to a backup location first. From the repository root, run:

```sh
mkdir -p "$HOME/.config"
test ! -e "$HOME/.config/rex" && test ! -L "$HOME/.config/rex" && ln -s "$PWD/rex" "$HOME/.config/rex"
```

Rex reads `~/.config/rex/init.lua` through the link. After you edit `rex/init.lua`, choose Reload Config in Rex.

## Open a project

Press Cmd+Shift+P in Rex and choose **Open Project…**. The picker lists direct subdirectories of `$DEV`, including links to directories. If the Rex server has no `DEV` variable, the picker uses `~/Dev`.

An **Open session** label means that Rex will switch to the session with that project name. Otherwise, Rex creates a session with one shell tab at the project root. The picker does not include the README preview from Herdr's `h-open`.

## Local Rex documentation

Run this command from the repository root to download or refresh the [official Rex docs](https://www.superlogical.com/rex/docs). The script uses Python 3 and needs no extra packages.

```sh
python3 scripts/sync-rex-docs.py
```

Open [the local index](docs/README.md) or search the pages with `rg --no-ignore -n 'term' docs/`. Git ignores `docs/`. Each refresh replaces the generated copy, so do not edit it by hand.
