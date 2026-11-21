# Rex Docs

> Documentation for Rex, the multiplexer for all work. Every page is also
> available as markdown by adding .md to its address, or by asking for
> text/markdown in the Accept header.

To find a topic, search the docs at https://www.superlogical.com/rex/docs/search.json?q=your+query,
which answers with the ten best-matching sections as JSON, best first,
each with its `url`, the `markdown` of its page, its `page` and
`heading`, and its `text`. Without `q` it answers with every section.
Every page together, in one file, is at https://www.superlogical.com/rex/docs/llms-full.txt.

These docs and the community feedback from the Rex Beta Discord are also
an MCP server, at https://www.superlogical.com/rex/community-mcp. It is open to
members of that Discord and read-only.

It uses MCP authorization (OAuth 2.1). A request without a token is answered
with 401 and a link to its protected resource metadata. Signing in goes
through Discord, which confirms the person is a member of the server, and
then asks them to allow the client. Clients that support MCP authorization
need only the address.

- [Installation](installation.md): At the current stage of beta testing, the macOS application and the Linux and FreeBSD server are available to all testers. The iOS application and the Windows application and server are available to…

## Customize

- [Configuration File](customize/config.md): Rex configuration is written in Lua and lives in a single file: init.lua. It binds keys, defines custom actions, declares the other servers you connect to, and more. It can load other Lua files (via…
- [Keyboard Shortcuts](customize/keyboard-shortcuts.md): Keyboard shortcuts are defined in the configuration file with rex.bind and removed with rex.unbind. A shortcut binds a key to an action, such as splitting a pane or switching sessions.
- [Key Sequences](customize/key-sequences.md): A key sequence is two or more keys pressed one after another, such as
- [Key Modes](customize/key-modes.md): A key mode is a named set of keyboard shortcuts that only apply while the mode is active. Modes let ordinary keys do something else for a while, such as making the arrow keys resize panes. They are…
- [Custom Actions](customize/actions.md): A custom action is a named Lua function defined in the configuration file with rex.action. Once defined, it works like any built-in action: it can be bound to a key, it appears in the command…
- [Custom UI](customize/custom-ui.md): A custom action can stop partway, ask the person a question in the command palette, and carry on with the answer. rex.ui.input asks for a line of text, and rex.ui.pick shows a list to choose from.

## Automate

- [The CLI](automate/cli.md): rex is the command-line interface to Rex.
- [Agents](automate/agent-skill.md): Rex ships with a built-in agent skill that enables agents such as Claude Code or Codex to efficiently open tabs, split panes, read a terminal’s screen, control connected Rex apps, and more.
- [Lua Scripts](automate/lua-scripts.md): rex do runs a Lua script against a Rex server.
- [Lua Events](automate/lua-events.md): A Lua script can keep running and react to what happens in Rex: a terminal changes directory, a program exits, a window closes, a session is created. A script asks for an event with rex.on.
- [Shell Scripting](automate/shell-scripting.md): You can also use the rex CLI with typical shell scripts to automate everything in Rex:
- [Server API](automate/server-api.md): The server documents its own API. You can list every method, read a method’s arguments and result, and call it, all from the CLI:

## Build for Rex

- [Program Status Protocol](build/program-status.md): A terminal escape sequence that lets a program tell the terminal what it is doing: idle, working, waiting on the user, finished, or failed, and why.

## Server

- [Installing on Linux](linux/installation.md): Rex can run as a server on Linux so that clients can access it as a remote host.
- [Installing on FreeBSD](freebsd/installation.md): Rex can run as a server on FreeBSD so that clients can access it as a remote host.
- [Installing on Windows](windows/installation.md): Rex can run as a server on Windows so that clients can access it as a remote host.
- [Running on Windows](windows/running.md): On Windows, every Rex server can only login as a single account: the account that installs the Windows service. Server Modes, Shared Server and Login Server are for Linux and FreeBSD, and don’t apply…
- [Server Modes](linux/server-modes.md): How you run a Rex server decides which account it runs as and who can connect to it. On Windows, there’s only the personal server, as Running on Windows explains.
- [Shared Server](linux/shared-server.md): The shared server is one Rex server that runs as the rex system account, as rex.service. Members of the rex group can connect to it, and every program they start runs as rex. It’s the simplest server…
- [Login Server](linux/login-server.md): The login server lets several people use Rex on one machine, each as their own operating system account, with their own files and permissions. It’s the server mode to use when people shouldn’t share…
- [Remote Access](linux/remote-access.md): This page documents how you access your servers remotely once you have Rex Server installed and running. On Linux or FreeBSD, Rex Server listens only on Unix sockets on that machine by default. On…
- [Upgrading](linux/upgrading.md): You can upgrade Rex using your standard package manager that you installed with. If you used the install.sh script, running that again is also safe; it merely detects and invokes your package manager.

## References

- [CLI Commands](reference/cli.md): This page lists every public rex command and flag. See The CLI for how to use them. Anything tagged Snapshot is on the snapshot channel and not yet in preview.
- [Server API Methods](reference/api.md): This page lists every method in the control API. See Server API for how to call them. Anything tagged Snapshot is on the snapshot channel and not yet in preview.
- [Mac Actions](reference/mac-actions.md): This page lists every action in the Rex for Mac command palette. Use the name to bind a key or to run it with rex do. Anything tagged Bleeding Edge is on that update channel and not yet in Preview.
- [Mac Settings](reference/mac-settings.md): This page lists every setting in Rex for Mac and where to find it. Anything tagged Bleeding Edge is on that update channel and not yet in Preview.
- [iOS Actions](reference/ios-actions.md): This page lists every action in the Rex for iOS command palette. Use the name to run it with rex do.
- [iOS Settings](reference/ios-settings.md): This page lists every setting in Rex for iOS and where to find it.
- [Rex Lua API](reference/lua.md): This page lists the full Lua API Rex exposes. Rex only adds API to the global rex table. Rex runs Lua 5.1 with the full standard library, including io, os, and require. The one exception is io.popen…
- [Events](reference/events.md): Rex emits an event whenever something changes: a window opens, a terminal changes directory, a program exits, a session is destroyed. Events can be handled in Lua with rex.on and rex.wait, or…
- [Privacy & Telemetry](reference/privacy.md): Rex doesn’t collect telemetry. It has no usage analytics, no crash reporting of its own, and no account or license checks.

## Beta

- [Community MCP](beta/community-mcp.md): Rex documentation, the changelog, and current and past discussions from the Rex Beta Discord are available to agents as an MCP server.
