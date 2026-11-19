# rex-config

Keyboard shortcuts for Rex, my terminal multiplexer.

## Install

If `~/.config/rex` exists, move it to a backup location first. From the repository root, run:

```sh
mkdir -p "$HOME/.config"
test ! -e "$HOME/.config/rex" && test ! -L "$HOME/.config/rex" && ln -s "$PWD/rex" "$HOME/.config/rex"
```

Rex reads `~/.config/rex/init.lua` through the link. After you edit `rex/init.lua`, choose Reload Config in Rex.
