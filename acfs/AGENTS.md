# AGENTS.md - Agentic Coding Flywheel Setup

This VPS is configured with the [Agentic Coding Flywheel Setup (ACFS)](https://github.com/Dicklesworthstone/agentic_coding_flywheel_setup) - a complete environment for multi-agent AI-assisted software development.

## Flywheel Workflow Overview

The flywheel workflow enables parallel multi-agent development with coordination:

```
1. Plan          Create beads (tasks) with dependencies using br
2. Prioritize    Use bv to find highest-impact work
3. Coordinate    Claim beads, communicate via Agent Mail
4. Execute       Multiple agents work in parallel on separate beads
5. Review        Cross-check each other's work with fresh eyes
6. Iterate       Continuous improvement cycle
```

**Key Principle**: Track all work via beads (not markdown TODOs). Communicate with fellow agents via Agent Mail. Mark beads as you progress.

## Quick Reference - Essential Commands

### Coding Agents

| Command | Description | Example |
|---------|-------------|---------|
| `cc` | Claude Code (Anthropic) - start interactive session | `cc` |
| `cod` | Codex CLI (OpenAI) - start interactive session | `cod` |
| `gmi` | Gemini CLI (Google) - start interactive session | `gmi` |

### Session Management (NTM - Named Tmux Manager)

| Command | Description | Example |
|---------|-------------|---------|
| `ntm spawn` | Create multi-agent session | `ntm spawn myproj --cc=2 --cod=1 --gmi=1` |
| `ntm list` | List active sessions | `ntm list` |
| `ntm attach` | Attach to session | `ntm attach myproj` |
| `ntm send` | Send prompt to agents | `ntm send myproj "Analyze this codebase"` |
| `ntm send --cc` | Send to Claude only | `ntm send myproj --cc "Focus on API layer"` |
| `ntm palette` | Open command palette | `ntm palette myproj` |
| `ntm deps` | Check dependencies | `ntm deps -v` |

### Issue Tracking (br - Beads Rust)

| Command | Description | Example |
|---------|-------------|---------|
| `br add` | Create new bead | `br add "Implement auth flow"` |
| `br list` | List all beads | `br list` |
| `br show` | Show bead details | `br show 42` |
| `br start` | Claim and start a bead | `br start 42` |
| `br done` | Mark bead complete | `br done 42` |
| `br comment` | Add comment to bead | `br comment 42 "Found root cause"` |
| `br block` | Set dependency | `br block 42 --by 41` |

### Task Prioritization (bv - Beads Viewer)

| Command | Description | Example |
|---------|-------------|---------|
| `bv` | Open TUI viewer | `bv` |
| `bv --robot` | Machine-readable output | `bv --robot` |
| `bv ready` | Show unblocked beads | `bv ready` |
| `bv critical-path` | Show blocking chain | `bv critical-path` |

### Agent Communication (am - Agent Mail)

| Command | Description | Example |
|---------|-------------|---------|
| `am register` | Register your agent name | `am register claude-1` |
| `am send` | Send message to agent | `am send codex-1 "Check my API changes"` |
| `am inbox` | Check your inbox | `am inbox` |
| `am broadcast` | Send to all agents | `am broadcast "Starting auth refactor"` |
| `am contacts` | List registered agents | `am contacts` |

### Repository Management (ru - Repo Updater)

| Command | Description | Example |
|---------|-------------|---------|
| `ru sync` | Sync all managed repos | `ru sync` |
| `ru status` | Check repo statuses | `ru status` |
| `ru commit` | Smart commit with AI message | `ru commit` |
| `ru list` | List managed repos | `ru list` |

### Session Memory (cm - CASS Memory)

| Command | Description | Example |
|---------|-------------|---------|
| `cm recall` | Search past sessions | `cm recall "auth implementation"` |
| `cm save` | Save current insight | `cm save "OAuth flow requires..."` |
| `cm playbook` | Generate playbook from patterns | `cm playbook auth` |

### Bug Scanning (ubs - Ultimate Bug Scanner)

| Command | Description | Example |
|---------|-------------|---------|
| `ubs scan` | Scan for issues | `ubs scan` |
| `ubs scan --fix` | Scan and auto-fix | `ubs scan --fix` |
| `ubs doctor` | Check UBS health | `ubs doctor` |

### Safety Tools

| Command | Description | Example |
|---------|-------------|---------|
| `dcg` | Destructive Command Guard - blocks dangerous git/fs operations | Automatic |
| `slb` | Two-person rule for dangerous commands | `slb approve <id>` |
| `acfs doctor` | Health check for ACFS installation | `acfs doctor` |

### Utility Commands

| Command | Description |
|---------|-------------|
| `cass` | Search agent session history |
| `caam` | Switch between AI provider accounts |
| `giil` | Download images from cloud share links |
| `csctf` | Convert AI chat share links to Markdown |
| `s2p` | Source code to LLM prompt generator |
| `mdwb` | Convert websites to Markdown for LLM |
| `tru` | Token-optimized notation for context efficiency |

## Tmux Navigation

ACFS uses `Ctrl-a` as the tmux prefix (not the default `Ctrl-b`).

| Keys | Action |
|------|--------|
| `Ctrl-a n` | Next window |
| `Ctrl-a p` | Previous window |
| `Ctrl-a [0-9]` | Switch to window N |
| `Ctrl-a h/j/k/l` | Move between panes |
| `Ctrl-a z` | Zoom/unzoom current pane |
| `Ctrl-a d` | Detach session (keeps running) |
| `Ctrl-a c` | Create new window |
| `Ctrl-a ,` | Rename current window |

## Documentation Links

- [ACFS GitHub Repository](https://github.com/Dicklesworthstone/agentic_coding_flywheel_setup)
- [Agent Flywheel Learning Hub](https://agent-flywheel.com/learn)
- [NTM Documentation](https://github.com/Dicklesworthstone/ntm)
- [Beads Rust (br)](https://github.com/Dicklesworthstone/beads_rust)
- [Beads Viewer (bv)](https://github.com/Dicklesworthstone/beads_viewer)
- [MCP Agent Mail](https://github.com/Dicklesworthstone/mcp_agent_mail)
- [Ultimate Bug Scanner](https://github.com/Dicklesworthstone/ultimate_bug_scanner)
- [CASS Memory](https://github.com/Dicklesworthstone/cass_memory)
- [Repo Updater (ru)](https://github.com/Dicklesworthstone/repo_updater)

## Installed Tools Summary

### Coding Agents
- **Claude Code (cc)**: Anthropic's AI coding assistant with extended thinking
- **Codex CLI (cod)**: OpenAI's coding agent
- **Gemini CLI (gmi)**: Google's AI coding assistant

### Agent Orchestration
- **NTM**: Named Tmux Manager - spawn and coordinate multi-agent sessions
- **Agent Mail (am)**: Inter-agent messaging and coordination
- **Beads Rust (br)**: Graph-aware issue tracking with dependencies
- **Beads Viewer (bv)**: TUI for prioritizing and viewing beads

### Development Tools
- **UBS**: Multi-layer bug scanning (syntax, semantic, LLM-powered)
- **CASS**: Unified search across agent session history
- **CM**: Procedural memory for learning from past sessions
- **RU**: Multi-repo sync and AI-driven commit automation
- **DCG**: Destructive Command Guard for Claude Code safety

### Language Runtimes
- **Bun**: Fast JavaScript/TypeScript runtime
- **uv**: Fast Python tooling
- **Rust (nightly)**: Systems programming with Cargo
- **Go**: For compiled CLI tools
- **Node.js (via nvm)**: JavaScript runtime

### CLI Enhancements
- **zsh + Oh My Zsh + Powerlevel10k**: Beautiful shell with plugins
- **ripgrep (rg)**: Fast code search
- **fzf**: Fuzzy finder
- **zoxide**: Smart directory jumping
- **atuin**: Shell history with search
- **lazygit**: Terminal UI for git
- **lsd/eza**: Modern ls replacements
- **bat**: cat with syntax highlighting

### Networking & Security
- **Tailscale**: Zero-config mesh VPN
- **gh**: GitHub CLI

## Workflow Best Practices

1. **Always read AGENTS.md first** when starting work on a project
2. **Register with Agent Mail** before beginning: `am register <your-name>`
3. **Check for existing beads** before creating new ones: `br list`
4. **Use bv for prioritization** to find highest-impact work: `bv ready`
5. **Communicate changes** via Agent Mail when starting/finishing work
6. **Mark beads as you progress**: `br start`, `br done`
7. **Review other agents' work** with fresh eyes periodically
8. **Run UBS** before committing: `ubs scan`
9. **Use cm recall** to learn from past sessions on similar tasks

## Getting Help

- Run `acfs doctor` to diagnose installation issues
- Run `onboard` for the interactive tutorial
- Check `~/.acfs/logs/` for installation logs
- Visit https://agent-flywheel.com/troubleshooting for common issues

---
*This file is auto-installed by ACFS. Customize it for your project's specific needs.*
