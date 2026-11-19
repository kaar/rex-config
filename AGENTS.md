# Rex documentation

Use the local [Rex documentation index](docs/README.md) for Rex questions. Search the mirror with `rg --no-ignore -n 'term' docs/`. Do not search the web for Rex documentation unless the user asks.

For changes to `rex/init.lua`, start with the [configuration guide](docs/customize/config.md) and the [keyboard shortcuts guide](docs/customize/keyboard-shortcuts.md). Use the [Lua API reference](docs/reference/lua.md) and [Mac actions reference](docs/reference/mac-actions.md) for function signatures and action names.

If the mirror is missing or does not answer the question, tell the user. Run `python3 scripts/sync-rex-docs.py` only when the user asks to download or refresh the mirror.
