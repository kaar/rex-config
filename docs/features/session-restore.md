---
title: "Session Restore"
canonical_url: https://www.superlogical.com/rex/docs/features/session-restore
---

# Session Restore

When you restart a Rex client (such as Rex for Mac, Windows, or iOS),
it restores all your sessions as-is with full history. This is because the
Rex Server is what stores all that state.

When you restart a Rex Server, it restores all your sessions, tabs, and panes
with their labels. If a pane was running a program that supports the
[Program Resume Protocol](../build/program-resume.md), then it will restart that
program. Otherwise, it will restart your shell in the working directory
you were in when the server last exited.

## Programs That Resume

Any program that supports the [Program Resume Protocol](../build/program-resume.md)
can resume. You must pair this with an opt-in [trust rule](#changing-what-resumes), too.

The program resume protocol is still very new, so Rex does have some
built-in support for some programs:

| Program | Resumes | Why |
| ----------- | ------- | -------------------------------------------- |
| Claude Code | Yes | Rex's hook reports the session. |
| Codex | No | Rex ships a rule, but nothing reports yet. |
| OpenCode | No | Rex ships a rule, but nothing reports yet. |
| Pi | After 1.6.1 | Pi reports for itself, from its first release after 1.6.1. |
| Gemini CLI | No | Rex ships a rule, but nothing reports yet. |
| Copilot CLI | No | Rex ships a rule, but nothing reports yet. |
| Crush | No | Rex ships a rule, but nothing reports yet. |

You can see an example in the [Resume Rules](../customize/resume-rules.md#example-neovim-sessions)
page how to configure Neovim to resume in less than 20 lines of Neovim Lua
configuration.

### Claude Code

Claude Code comes back in the same pane, in the same conversation, with the
flags the rule keeps, such as `--model opus`. When you quit it, you're
in your shell in the same directory.

The resumed Claude Code starts with the environment of a new terminal, not
the one it had. A variable you exported by hand before starting it is gone.

Resuming Claude Code needs:

- The hook that `rex skill setup` installs. See
  [Agent Setup](../automate/agent-skill.md#agent-setup). The hook tells the
  terminal how to start the session again.
- A [trust rule](#changing-what-resumes) that trusts the command. Rex ships
  one for Claude Code.
- A shell that Rex can start a program through: bash, zsh, fish, nushell,
  sh, ash, dash, ksh, mksh, oksh, pdksh, or yash.

### Pi

Pi has integrated support for the program resume protocol since 1.6.1
and Rex ships with a built-in rule to trust it. Pi comes back in
the same session, without the flags it was started with.

If you keep Pi's sessions in another directory, add a rule for it. See
[Resume Rules](../customize/resume-rules.md#pi).

## Changing What Resumes

Trust rules decide which programs Rex resumes. This still requires that
the programs _report_ their resume command. Change them in
[init.lua](../customize/config.md):

```lua
rex.set("resume.defaults", false)
```

Turns off every rule Rex ships. Sessions are still restored, and no program
is resumed.

```lua
rex.set("resume.trust.codex", false)
```

Removes the rule for Codex and leaves the others in force.

```lua
rex.set("resume.trust.claude.dir", "~/code")
```

Resumes Claude Code only when it runs in `~/code` or a directory below it.

```lua
rex.set("resume.trust.claude.flags.--dangerously-skip-permissions", false)
```

Stops resuming a Claude Code that was started with
`--dangerously-skip-permissions`. It doesn't bring Claude Code back without
the flag. The rule no longer lists the flag, so Rex trusts no command
with it.

```lua
rex.set("resume.trust.claude.flags.--dangerously-skip-permissions", "drop")
```

Brings Claude Code back without `--dangerously-skip-permissions`, so the
resumed session has its permission checks again.

`rex config check` lists the rules in force and the ones you turned off.
A change applies when the server reloads its config. See
[Resume Rules](../customize/resume-rules.md) for everything a rule can do.

## When a Program Doesn't Resume

When a program can't resume, its pane comes back as a plain shell, in the
same directory, as if no program had been saved. That happens when:

- The rules in force at the restart don't trust the command, for example
  because you removed the rule, or removed or dropped a flag the command uses.
- `init.lua` stopped with an error before it finished loading. Rex trusts
  nothing until it loads in full.
- The program named its directory, and that directory is gone.
- Rex already tried to resume the same saved program once, for example
  before a crash. It never tries twice.
- Your shell isn't one Rex can start a program through.
- Program resume is off on this server, on Windows or as root.

Some programs are never saved, so nothing resumes after the restart:

- The program runs under another program that isn't a shell, such as a
  sandbox. Running it alone would leave the sandbox out.
- The run has no session to resume, such as `claude -p`.
- You quit the program. Its record goes away about 2 seconds after it exits.
- No rule trusted it when the server stopped.

## Turning It Off

To start a server without its saved sessions, pass `--restore=false`:

```sh
rex server run --restore=false
```

The server then restores nothing and saves nothing, so the saved sessions
are still there for the next start without the flag.

To delete the saved sessions, stop the server with `--discard`. The next
start begins with none:

```sh
rex server stop --discard
```

Pass `--state-dir` too if the server was started with one.

## Where State Is Kept

The server saves its sessions in `servers/<id>/snapshot` below its state
directory:

| Server                             | State directory                     |
| ---------------------------------- | ----------------------------------- |
| Personal server on Linux, FreeBSD  | `~/.local/state/rex`, or `$XDG_STATE_HOME/rex` |
| Personal server on macOS, Mac app  | `~/Library/Application Support/rex` |
| Windows                            | `%LocalAppData%\rex`                |
| Shared server                      | `/var/lib/rex`, or `/var/db/rex` on FreeBSD |
| `rex server run --state-dir DIR`   | `DIR`                               |

On Linux, macOS, and FreeBSD, only the account the server runs as can read
the saved files. Files are `0600` and directories are `0700`. On the shared
server, that account is `rex`.

**A saved command can hold a secret.** Rex saves the command a restart runs,
with every flag the rule keeps, such as a system prompt passed to Claude
Code, in plain text. We plan to encrypt these files in the future where a
source to store keys is available.

## Debugging

To see what a terminal would resume, list its records from inside it:

```sh
rex block call -b "$REX_BLOCK" program_resume_records
```

```json
{"records":[{"owner":{"pid":96556,"name":"2.1.332"},"program":"claude","cwd":"/Users/you/Developer/superlogical/rex-docs","reported_at":"2026-11-25T22:31:28Z","chosen":true,"trusted":true,"rule":"claude","command":["claude","--resume","4394937c-b07a-4bd5-b6d0-034e7091ff1f","--model","opus"]}]}
```

`chosen` is the record a restart would resume, and `trusted` says whether a
rule trusts it. For a trusted record, `command` is what a restart runs. When
the program reported something else, such as a flag your rule drops, the
record also has `reported_command`, the command as the program sent it.

An untrusted record has an `untrusted_reason` instead:

| Reason              | Meaning                                                      |
| ------------------- | ------------------------------------------------------------ |
| `no_rule`           | No rule names the command.                                   |
| `dir_not_allowed`   | The program runs outside the directories the rule allows.    |
| `flag_not_listed`   | The program was started with a flag the rule doesn't list.   |
| `flag_value`        | A flag the rule lists has a value that doesn't fit the rule. |
| `flags_differ`      | The command goes on past a rule without flags, or a saved command has a flag the rule now drops. |
| `program_differs`   | The process that reported isn't the program the command starts. |
| `wrapped`           | The program runs under another program that isn't a shell.   |
| `launch_unreadable` | Rex couldn't read how the program was started.               |
| `config_incomplete` | `init.lua` stopped with an error before it finished loading. |

An empty list means no program in the terminal has reported, or the one
that did has exited.

After a restart, the server log says what it did with each saved program.
It logs the program's name and never the command:

```
2026/11/25 14:36:10 INFO  terminal: resuming saved program command="rex server run" program=claude rule=claude
2026/11/25 14:38:27 INFO  terminal: not resuming saved program, starting a shell command="rex server run" program=claude reason=not_trusted trust_reason=no_rule rule=""
```

`reason` is one of `not_trusted`, `settings_incomplete`, `dir_gone`,
`already_tried`, `shell_unsupported`, or `program_resume_off`. A program
that was never saved logs nothing.

For a server started by `rex server start` or the Mac app, read the log
with `rex server logs`. For the systemd user service, run
`journalctl --user -u rex`. For the shared server, see
[Logs](../linux/shared-server.md#logs), and on Windows, see
[Logs](../windows/running.md#logs).
