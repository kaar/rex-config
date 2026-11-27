---
title: "Resume Rules"
canonical_url: https://www.superlogical.com/rex/docs/customize/resume-rules
---

# Resume Rules

Resume rules decide which programs Rex can automatically resume when it
restores a session. Each rule is a setting in your [configuration file](config.md),
set with `rex.set`:

```lua
-- Only resume Claude Code in projects under ~/code
rex.set("resume.trust.claude.dir", "~/code")

-- Never resume Codex
rex.set("resume.trust.codex", false)
```

Rex ships rules for a few agents, so most people never need to write one.
[Session Restore](../features/session-restore.md) explains what restoring brings
back and when.

## How Rex Decides

A program that wants to be resumed reports the command that starts it again,
using the [Program Resume Protocol](../build/program-resume.md). Rex resumes the
program after a restart without asking you as long as a rule exists to allow
it.

A rule has three parts:

| Part | Description |
| --- | --- |
| `command` | The start of the resume command, such as `claude --resume <uuid>`. |
| `flags` | Each flag the program can be started with, and whether it comes back when the program is resumed. |
| `dir` | The directories the program may be resumed in. |

Rex doesn't trust a program's report. It takes the report it sent and
cross-checks it with your rules and takes your rules as truth.

For a rule with flags, Rex filters the command that a restart runs. Rex
takes the command sent by the report, then drops any disallowed flags from
the command line. Example:

```
started as  claude --dangerously-skip-permissions --model opus -c "fix the tests"
resumed as  claude --resume 015d3962-... --dangerously-skip-permissions --model opus
```

Rex also performs a number of its own checks. For example, the process must
also be the program the command starts. For example,
`claude` and `/opt/homebrew/bin/claude` both count as `claude`, and so does
`node /opt/homebrew/bin/claude`, the way an npm install of Claude Code runs.

A program that runs under a program other than a shell, such as a sandbox, is
not trusted. Resuming the command alone would leave the sandbox out.

## Built-in Rules

| Rule | Command | Flags |
| --- | --- | --- |
| `claude` | `claude --resume <uuid>` | 44 kept, 12 dropped |
| `codex` | `codex resume <uuid>` | None |
| `copilot` | `copilot --resume <uuid>` | 57 kept, 10 dropped |
| `crush` | `crush --session <uuid>` | 8 kept, 6 dropped |
| `gemini` | `gemini --resume <uuid>` | 20 kept, 8 dropped |
| `opencode` | `opencode --session <id>` | None |
| `pi` | `pi --session <uuid>` | None |

The `claude` rule keeps the flags that shape a session, such as `--model`,
`--permission-mode` and `--dangerously-skip-permissions`. It drops the flags
that pick a session or start a task, such as `--continue`, because
`--resume` does that job instead. A Claude Code started with `--print`, or with
any flag the rule doesn't list, is not resumed.

The `copilot`, `crush` and `gemini` rules sort flags the same way. Each one
keeps the flags that skip permission prompts, such as `--yolo`, so a session
that skipped them still skips them when it comes back.

A rule without flags trusts its command with nothing after it.

[Session Restore](../features/session-restore.md#programs-that-resume) lists which
of these agents report today.

### Turning Off the Built-in Rules

```lua
rex.set("resume.defaults", false)
```

Every built-in rule is left out, including one that your file changed a part
of. Rex warns about each such change, since you probably expected it to apply.
A rule your file sets in full is kept, even if it has the name of a built-in
rule.

### Changing a Built-in Rule

You can change any of the built-in rules the same way you'd configure
a custom rule: via `rex.set` and named as `resume.trust.<program>`.

Remove a rule with `false`:

```lua
rex.set("resume.trust.codex", false)
```

Limit a rule to one directory, or a list of them. A program started in a
directory inside one of them counts too:

```lua
rex.set("resume.trust.claude.dir", "~/code")
rex.set("resume.trust.claude.dir", { "~/code", "/srv/work" })
```

`~` is the home directory of the user the Rex server runs as.

Change one flag with a key below `flags`. The flag's name is everything after
`flags.`:

```lua
-- Don't resume a Claude Code started without permission checks
rex.set("resume.trust.claude.flags.--dangerously-skip-permissions", false)
```

`false` takes the flag out of the rule, so a program started with that flag is
not resumed at all. `"keep"` and `"drop"` set whether the flag comes back.

```lua
-- Resume Claude Code with permission checks turned back on
rex.set("resume.trust.claude.flags.--dangerously-skip-permissions", "drop")
```

Since Rex builds the command from the rule, a dropped flag stays out even
when the program reports it.

To replace a built-in rule, set the whole rule. Nothing of the built-in rule is
kept:

```lua
rex.set("resume.trust.claude", {
  command = { "claude", "--resume", rex.match.uuid },
  flags = {
    ["--model"] = { "keep", values = 1 },
    ["--continue"] = "drop",
  },
})
```

The calls take effect in order, so a whole rule set after `claude.dir`
replaces that `dir` too.

## Adding a Rule

Add a rule with a new name under `resume.trust`:

```lua
rex.set("resume.trust.lazygit", {
  command = { "lazygit" },
  dir = "~/code",
})
```

`command` is a list. Its first element is the program's name or an absolute
path, and a name such as `lazygit` matches only that name, never a path such
as `/tmp/x/lazygit`. Each later element is one of these:

| Element | Matches |
| --- | --- |
| `"--resume"` | That exact string. |
| `{ "--resume", "-r" }` | Any one of the strings. |
| `rex.match.uuid` | A UUID, such as `015d3962-6f9e-45c3-92bc-c7cef5068215`. |
| `rex.match.id` | 1 to 128 letters, digits and underscores. |
| `rex.match.under(dir)` | An absolute path inside `dir`, but not `dir` itself. |

`rex.match.under` compares the path as text, so a path with `..` in it never
matches. Right before Rex resumes the program, it checks the path again after
following symbolic links.

`flags` is a table keyed by flag name. A flag that takes no value is `"keep"`
or `"drop"`. A flag that takes values is a table that says how many:

```lua
flags = {
  ["--verbose"] = "keep",
  ["--continue"] = "drop",
  ["--model"] = { "keep", values = 1 },
  ["--debug"] = { "keep", values = "optional" },
  ["--add-dir"] = { "keep", values = "many" },
}
```

| `values` | Takes |
| --- | --- |
| `1` | The next argument, even one that starts with `-`. |
| `"optional"` | The next argument, unless it starts with `-`. |
| `"many"` | Every argument up to the next one that starts with `-`. |

`--name=value` gives a long flag its value in the same argument. Anything that
isn't a flag or a flag's value, such as a prompt, never comes back, and neither
does anything after a bare `--`.

A rule without `flags` trusts its command and nothing after it, and never
reads the command line the program was started with. A rule with `flags` is
stricter: a program started with a flag the rule doesn't list is not resumed.

`dir` is one directory or a list, as for a built-in rule. Without it, the
program may be resumed in any directory.

## Disabling Program Resumption

Disable the builtins and remove any custom rules:

```lua
rex.set("resume.defaults", false)
```

Verify with `rex config check`:

```
$ rex config check
...
resume rules: 0
  not in force:
    claude, codex, copilot, crush, gemini, opencode and pi off because resume.defaults is false at init.lua:1
```

Sessions are still restored. Each terminal starts a plain shell in its saved
directory instead of the program that ran there. This can't be disabled via
configuration today.

When resumption is disabled, reporting is still allowed and still saved.
If you disable resume, run some programs, then enable resume, those programs
will resume on the next restart.

## Example: Neovim Sessions

Neovim doesn't report a resume command on its own, so this example has two
parts. In Neovim's configuration, report `nvim -S <file>` each time a session
is saved:

```lua
-- ~/.config/nvim/init.lua
local token = vim.env.OSC7577_TOKEN
vim.env.OSC7577_TOKEN = nil

vim.api.nvim_create_autocmd("SessionWritePost", {
  callback = function()
    if not token then return end
    local argv = { "nvim", "-S", vim.v.this_session }
    for i, arg in ipairs(argv) do argv[i] = vim.base64.encode(arg) end
    -- This process is Neovim's server. The terminal runs its parent, the TUI.
    local body = ("pid=%d:time=%d:argv=%s"):format(
      vim.uv.os_getppid(), os.time(), table.concat(argv, ","))
    local mac = vim.fn.sha256(body .. ":" .. token)
    io.stderr:write("\27]7577;", body, ":mac=", mac, "\27\\")
  end,
})
```

In Rex's configuration, trust that command for session files in one
directory:

```lua
rex.set("resume.trust.nvim", {
  command = { "nvim", "-S", rex.match.under("~/.local/state/nvim/sessions") },
})
```

`-S` runs the session file as a script, so a rule that trusted any path would
run any file. `rex.match.under` limits it to the one directory.

Save a session there with
`:mksession ~/.local/state/nvim/sessions/work.vim`, and Rex resumes Neovim
with it. A session saved anywhere else isn't resumed.

A wrapper script that reports for another program and then runs it, like the
one on the [protocol page](../build/program-resume.md), can't be trusted by a
rule. Its report starts with the wrapper, and the process Rex finds is the
program it ran.

## Debugging

`rex config check` lists the rules in force, the parts your file changed, and
the rules that are not in force. For this file:

```lua
rex.set("resume.trust.codex", false)
rex.set("resume.trust.claude.dir", "~/code")
rex.set("resume.trust.claude.flags.--dangerously-skip-permissions", false)
rex.set("resume.trust.nvim", {
  command = { "nvim", "-S", rex.match.under("~/.local/state/nvim/sessions") },
})
```

```
$ rex config check
...
resume rules: 7
  claude (built in)
    command: claude --resume <uuid>
    dir: ~/code (init.lua:2)
    flags: 43 kept, 12 dropped
      --dangerously-skip-permissions removed (init.lua:3)
  copilot (built in)
    command: copilot --resume <uuid>
    flags: 57 kept, 10 dropped
  crush (built in)
    command: crush --session <uuid>
    flags: 8 kept, 6 dropped
  gemini (built in)
    command: gemini --resume <uuid>
    flags: 20 kept, 8 dropped
  nvim (init.lua:4)
    command: nvim -S <path under ~/.local/state/nvim/sessions>
  opencode (built in)
    command: opencode --session <id>
  pi (built in)
    command: pi --session <uuid>
  not in force:
    codex removed at init.lua:1
```

A rule with a mistake is left out, with a warning at the line that caused it,
and the other rules still apply. A mistake in a change to a built-in rule
leaves out the whole built-in rule. Here line 3 misspells `"keep"`:

```lua
rex.set("resume.trust.codex", false)
rex.set("resume.trust.claude.dir", "~/code")
rex.set("resume.trust.claude.flags.--dangerously-skip-permissions", "keeep")
```

```
$ rex config check
...
resume rules: 5
  copilot (built in)
    command: copilot --resume <uuid>
    flags: 57 kept, 10 dropped
  crush (built in)
    command: crush --session <uuid>
    flags: 8 kept, 6 dropped
  gemini (built in)
    command: gemini --resume <uuid>
    flags: 20 kept, 8 dropped
  opencode (built in)
    command: opencode --session <id>
  pi (built in)
    command: pi --session <uuid>
  not in force:
    claude left out for a mistake, see the warning for init.lua:3
    codex removed at init.lua:1
warning init.lua:3: setting: resume.trust.claude: flags: "--dangerously-skip-permissions": unknown action "keeep", want "keep" or "drop", so this rule is ignored
```

`rex config reload` applies new rules to running terminals at once. If a
reload fails, the rules from the last load that worked stay in force. If no
load has worked since the server started, nothing is resumed until one does.

To see why a program in a terminal isn't trusted, list the terminal's records:

```sh
rex block call -b "$REX_BLOCK" program_resume_records
```

A record that isn't trusted has an `untrusted_reason`:

| Reason | Description |
| --- | --- |
| `no_rule` | No rule names the command. A path outside a `rex.match.under` directory gives this reason. |
| `program_differs` | The process isn't the program the command starts. |
| `wrapped` | The process runs under a program other than a shell, such as a sandbox. |
| `flag_not_listed` | The program was started with a flag the rule doesn't list. |
| `flag_value` | A flag's values don't fit the rule, such as a value for a flag that takes none. |
| `flags_differ` | The command goes on past a rule without `flags`, or a saved command has a flag the rule now drops. |
| `dir_not_allowed` | The program would be resumed outside the directories the rule allows. |
| `launch_unreadable` | Rex couldn't read the program's command line. |
| `config_incomplete` | `init.lua` failed before its end, and no earlier load worked. |
