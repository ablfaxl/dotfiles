# Developer Setup Audit

Date: 2026-09-18
Host: MacBook Pro, Apple Silicon
Scope: Phase 1 audit only. No tools were installed and no shell/editor/system configuration was changed.

## Executive Summary

Your machine already has a strong developer base: Homebrew, ZSH, Starship, tmux, Neovim, lazygit, fzf, ripgrep, fd, eza, bat, delta, pnpm, Bun, uv, OrbStack, Docker CLI, Cursor, VS Code, and a dotfiles repository.

The main problem is not lack of tools. The main problem is configuration drift:

- Active `~/.zshrc` is a large Oh My Zsh + Powerlevel10k file, while this repo contains a cleaner XDG-style ZSH setup that is not fully active.
- `~/.zprofile` and `~/.zshenv` are symlinks to `/Users/ablfaxl/project/Github/dotfiles/...`, but the current repo is `/Users/ablfaxl/project/dotfiles`.
- `~/.zprofile` is currently a broken symlink.
- PATH has duplicates and mixed runtime managers/locations.
- Several requested modern tools are missing from PATH: `zoxide`, `mise`, `btop`, `yq`, `redis-cli`.
- Homebrew reports many outdated formulae and casks.
- Shell startup is slow and noisy because `fastfetch` runs on every interactive shell and Powerlevel10k/gitstatus errors appear in the sandboxed audit.
- `c` is currently aliased to `clear`, which conflicts with the requested project selector.
- `z` is not currently available because `zoxide` is missing.
- `dev`, `devtmux`, and `doctor` do not exist yet.

Recommended direction: keep ZSH, remove configuration drift, use Starship as the prompt, use a small plugin set, add `zoxide`, add a safe project selector as `c`, add `dev` as the Finglish cheatsheet, standardize Git/tmux/scripts in this repo, and document Cursor/VS Code rather than mutating private app files.

## System

| Item | Status | Details |
| --- | --- | --- |
| macOS | Installed | macOS 27.0, build 26A428 |
| CPU architecture | Installed | `arm64`, Apple Silicon |
| Xcode Command Line Tools | Installed | `/Library/Developer/CommandLineTools` |
| Homebrew | Installed | Homebrew 7.0.4 at `/opt/homebrew/bin/brew` |
| Shell | Installed | ZSH 5.9 |
| Current repo | Present | `/Users/ablfaxl/project/dotfiles` |

## Homebrew

Installed formulae include the important core tools: `bat`, `eza`, `fd`, `fzf`, `gh`, `git-delta`, `jq`, `lazygit`, `neovim`, `pnpm`, `ripgrep`, `starship`, `tmux`, `tealdeer`, `postgresql@14`, `mysql`, `colima`, `bun`, `go`, `rustup`, `nvm`.

Installed casks include: `ghostty`, `kitty`, `alt-tab`, `copyq`, `maccy`, `monitorcontrol`, `openvpn-connect`, `sf-symbols`, `sublime-text`, `vscodium`, fonts, and others.

Outdated items: Homebrew reports many outdated formulae/casks, including core tools such as `bat`, `fd`, `fzf`, `gh`, `jq`, `lazygit`, `neovim`, `pnpm`, `ripgrep`, `starship`, `tmux`, plus casks such as `alt-tab`, `burp-suite`, `copyq`, `kitty`, and fonts.

Potential issue: both `copyq` and `maccy` are installed. They overlap as clipboard managers.

## Terminal and Shell

### Active ZSH

Active `~/.zshrc`:

- Uses Oh My Zsh from `~/.oh-my-zsh`.
- Uses Powerlevel10k.
- Also has Starship installed, but active prompt config is Powerlevel10k.
- Sources Powerlevel10k twice: once from `~/powerlevel10k/...` and once from Homebrew.
- Runs `fastfetch` on every shell startup.
- Loads `nvm` on startup.
- Adds PATH entries repeatedly.
- Defines personal aliases directly in the file.

Measured interactive shell startup:

- About `1.93s` in audit environment.
- Startup output is noisy because `fastfetch` runs automatically.
- Powerlevel10k/gitstatus produced initialization errors during sandboxed audit.

### ZSH Frameworks and Plugins

Installed/configured:

- Oh My Zsh at `~/.oh-my-zsh`.
- XDG Oh My Zsh copy/plugins at `~/.config/oh-my-zsh`.
- Powerlevel10k installed via Homebrew and also present under `~/powerlevel10k`.
- Plugins/directories found: `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-autocomplete`, `fast-syntax-highlighting`, `zsh-completions`.

Not found:

- Zinit
- Antidote

Potential conflicts:

- Multiple Oh My Zsh locations.
- Multiple plugin copies.
- Both Powerlevel10k and Starship are present.
- `zsh-autocomplete` can conflict with simpler completion/highlighting setups.

## PATH

Current PATH includes duplicate entries and mixed runtime sources:

- `~/.mimocode/bin` repeated.
- `~/.local/bin` repeated.
- `~/.bun/bin` repeated.
- `/opt/nvim-linux64/bin` appears on macOS.
- NVM path is hardcoded: `~/.nvm/versions/node/v24.13.0/bin`.
- pnpm path is present: `~/Library/pnpm`.
- Homebrew path is present: `/opt/homebrew/bin`.
- MySQL path is present: `/opt/homebrew/opt/mysql/bin`.
- Python 3.9 user bin is present: `~/Library/Python/3.9/bin`.

Recommended: centralize PATH construction in a single file, deduplicate entries, remove Linux-only `/opt/nvim-linux64/bin` from macOS PATH, and avoid hardcoding one Node version.

## Requested Tool Audit

| Tool | Status | Details |
| --- | --- | --- |
| Homebrew | Installed | 7.0.4 |
| ZSH | Installed | 5.9 |
| Oh My Zsh | Installed | Active in `~/.zshrc` |
| Zinit / Antidote | Missing | Not detected |
| Starship | Installed | 1.24.2, not the active prompt |
| Powerlevel10k | Installed | Active, duplicated sources |
| Ghostty | Installed as cask | App exists in Homebrew casks; `ghostty` CLI not on PATH |
| iTerm2 | Missing | Not detected |
| Apple Terminal | Installed | Native macOS app |
| tmux | Installed | 3.6a |
| Neovim | Installed | 0.12.1 |
| Git | Installed | Apple Git 2.54.0 |
| lazygit | Installed | 0.61.0 |
| fzf | Installed | 0.71.0 |
| ripgrep | Installed | 15.1.0 |
| fd | Installed | 10.4.2 |
| eza | Installed | 0.23.5 |
| bat | Installed | 0.25.0 |
| zoxide | Missing | Required for requested `z` behavior |
| delta | Installed | 0.19.2 |
| jq | Installed | Apple `jq-1.7.1`; Homebrew `jq` also installed |
| yq | Missing | Listed in repo package file but not installed |
| btop | Missing | `htop` installed instead |
| mise | Missing | Not installed |
| Node.js | Installed | `v24.13.0` from `~/.local/bin/node`/NVM-era PATH |
| pnpm | Installed | 10.33.0 |
| npm | Installed | 11.6.2 |
| Bun | Installed | 1.2.5 via Homebrew |
| Python | Installed | `/usr/bin/python3` 3.9.6; Homebrew Python 3.10/3.13 installed |
| uv | Installed | 0.11.26 from `~/.local/bin` |
| Rust | Partial | `rustup` installed by Homebrew; `rustc` and `cargo` not on PATH |
| Docker CLI | Installed | 29.4.0 |
| OrbStack | Installed | App exists; Docker context active |
| PostgreSQL CLI | Installed | `psql` 14.15 |
| Redis CLI | Missing | Not detected |
| VS Code | Installed | CLI reports 1.113.0 |
| Cursor | Installed | CLI reports 3.5.33 |
| GitHub CLI | Installed | 2.96.0, not logged in |

## Git

Active `~/.gitconfig`:

- Has personal Git identity.
- Uses Apple Git global default branch from system config.
- Has Git LFS filters configured, but `git lfs` command is missing.
- Does not currently enable delta, `zdiff3`, or the richer repo Git config.
- Has Cursor Origin credential helpers.

Repo `config/git/config`:

- More complete and professional than active `~/.gitconfig`.
- Includes delta pager integration, default branch `main`, useful aliases, rerere, pull rebase, and excludesfile.
- Uses `merge.conflictstyle = diff3`; requested target is `zdiff3`.
- Includes some dangerous aliases that should be reconsidered before adopting globally:
  - `cleanup` runs `git clean -df` and `git stash clear`.
  - `grhh` in aliases resets hard.
  - `forget` deletes gone branches with `-D`.
  - `delete-merged-branches` deletes branches.

Recommended: create a safe `git/gitconfig` for the new architecture, keep identity in a local/private include, enable delta only if installed, switch conflict style to `zdiff3`, and avoid destructive aliases.

## tmux

Active `~/.tmux.conf`:

- Uses prefix `C-a`.
- Enables mouse.
- Has simple split bindings.
- Uses TPM with `tmux-sensible` and `tmux-resurrect`.
- Uses `screen-256color`.

Repo `config/tmux/tmux.conf`:

- More complete and modern.
- Uses `tmux-256color` with RGB override.
- Has better pane/window navigation.
- Uses TPM plugins: `tmux-sensible`, `tmux-prefix-highlight`, `tmux-better-mouse-mode`.
- Plugin path expects `$HOME/.config/tmux/plugins/tpm/tpm`, but that directory is missing.

Installed TPM:

- Exists under `~/.tmux/plugins/tpm`.
- Missing under `~/.config/tmux/plugins`.

Recommended: keep tmux simple, avoid plugin dependency unless needed, and add `devtmux` as a separate script.

## Neovim

Active Neovim config exists at `~/.config/nvim`.

Observed:

- Uses `lazy.nvim`.
- Has Treesitter, Telescope, nvim-tree, LSP, Mason, completion, formatting, linting, gitsigns, lazygit integration, which-key, todo-comments, lualine, bufferline, auto-session.
- There is a stale swap file: `~/.config/nvim/.init.lua.swp`.
- `init.lua` is very small and appears to bootstrap a simpler Catppuccin setup; `lua/ablfaxl/lazy.lua` contains a more complete modular setup. This suggests config drift or incomplete wiring.
- Plugin file `azygit.lua` appears to be a typo for `lazygit.lua`; not harmful by itself, but messy.
- `null-ls.nvim` is configured; that project is archived/unmaintained and should be replaced or removed later.
- Mason ensures `tsserver`, but newer LSP naming may need checking before changes.

Recommended: do not replace Neovim blindly. First wire the existing modular setup intentionally, remove stale swap files after backup/approval, replace deprecated pieces incrementally, and keep startup fast.

## Cursor and VS Code

Installed:

- `/Applications/Cursor.app`
- `/Applications/Visual Studio Code.app`
- `cursor` CLI: 3.5.33
- `code` CLI: 1.113.0

Both CLIs emitted code-signing related Electron messages during audit, but still returned versions/extensions.

VS Code:

- Many extensions installed. Useful: ESLint, Prettier, Tailwind CSS, Python/Pylance, Go, YAML, Playwright, Git Graph, GitLens-like tools, ChatGPT/Copilot/Continue.
- Duplicates/overlap: multiple Git UI extensions, multiple themes, multiple AI assistants.
- Settings include custom UI CSS, fixed theme/font choices, `update.mode = none`, Wakatime, Prettier format-on-save, ESLint fix-on-save.

Cursor:

- Many extensions installed, more than VS Code.
- Duplicates/overlap: multiple themes, multiple Git tools, multiple container/Kubernetes tools, multiple AI/code assistants.
- Settings include terminal PATH override hardcoding Node `v24.13.0`.
- Settings force TypeScript formatter to built-in TypeScript while global default is Prettier; this may conflict with Prettier expectations.
- Cursor config should be documented, not modified directly without approval.

Recommended: document minimal extension sets and settings. Do not modify Cursor internals/private files.

## Docker / OrbStack / Colima

Installed:

- Docker CLI 29.4.0.
- OrbStack app installed and active Docker context is `orbstack`.
- Colima is installed via Homebrew.

Potential duplication:

- OrbStack and Colima both solve local container runtime. Since OrbStack is active, Colima should probably be optional or documented as unused, not both started by default.

`orbctl list` succeeded when run outside the sandbox, but printed no machines/containers.

## Runtime Management

Current state:

- Node is available as `v24.13.0`.
- `nvm` is installed and active in `~/.zshrc`.
- `pnpm` and `npm` are installed under `~/.local/bin`.
- `bun` is installed by Homebrew.
- Repo docs/scripts prefer `fnm`, but `fnm` is not installed.
- `mise` is not installed.
- Python exists in several places: system Python 3.9.6, Homebrew Python 3.10 and 3.13, and `uv`.
- `rustup` is installed, but `rustc`/`cargo` are not currently on PATH.

Recommended decision point:

- Choose one runtime manager path.
- For a minimal professional setup, `mise` is a good candidate if you want one manager for Node/Python/Go/etc.
- If you prefer a lighter Node-only path, use `fnm` and keep Python via `uv`.
- Avoid having NVM, fnm, mise, Homebrew Node, and hardcoded Node paths all active at once.

## Aliases and Functions

Active interactive aliases sampled:

- `ga='git add .'`
- `gc='git commit --verbose'`
- `gp='git push'`
- `gl='git pull'` from Oh My Zsh, conflicting with requested `gl = git log`
- `ll='ls -lh'`
- `la='ls -lAh'`
- `c=clear`, conflicting with requested project selector
- `reload='source ~/.zshrc'`
- `z` is not available
- `dev` is not available
- `devtmux` is not available
- `doctor` is not available

Repo `config/aliasrc` has a richer alias set, but active `~/.zshrc` is not using this repo's XDG ZSH flow.

Potentially dangerous aliases/functions in repo:

- `lock_clean` removes lockfiles.
- `nm_clean` removes `node_modules`.
- `grhh` hard resets Git.
- `cleanup` in Git config can delete untracked files and clear stashes.

Recommended: keep short memorable aliases, but avoid destructive shortcuts unless they prompt for confirmation.

## Existing Dotfiles

Current repo structure:

- `bin/` user scripts: `cpwd`, `ex`, `ffd`, `fix-ssh-perm`, `killport`, `localip`, `newscript`, `port`, `renpm`, `topmem`.
- `config/`: alacritty, aliasrc, env, git, gh, inputrc, npm, ripgrep, starship, tmux, wget, zed, zsh.
- `home/`: zprofile, zshenv.
- `packages/`: brew, brew-casks, apt, pacman, aur, npm globals.
- `scripts/`: setup/validation scripts.
- `server-config/`: server shell setup.

Repository working tree:

- Clean at audit time.

Symlink issue:

- `~/.zprofile` -> `/Users/ablfaxl/project/Github/dotfiles/home/zprofile` is broken.
- `~/.zshenv` -> `/Users/ablfaxl/project/Github/dotfiles/home/zshenv` points outside this current repo.
- Many `~/.config/*` symlinks also point to `/Users/ablfaxl/project/Github/dotfiles/...`.

Recommended: after backup and approval, relink to the current repo path or confirm whether `/Users/ablfaxl/project/Github/dotfiles` is the canonical repo.

## Project Directories

Detected project root:

- `~/project`

Detected first-level projects:

- `~/project/js-algorithms`
- `~/project/high-tech`
- `~/project/dotfiles`
- `~/project/Zihome`
- `~/project/pnr`
- `~/project/arch-architect`
- `~/project/sni-spoof`
- `~/project/dakhl`
- `~/project/arta_project`
- `~/project/Github`
- `~/project/raydad-project`
- `~/project/FitFlow`

Not detected during audit:

- `~/Developer`
- `~/Projects`
- `~/Code`
- `~/Workspace`

Recommended: project selector `c` should include only existing roots, starting with `~/project`, and optionally discover nested directories under `~/project/Github`.

## Useful macOS Developer Tools

Installed or present:

- Xcode Command Line Tools
- Ghostty cask
- OrbStack
- AltTab
- Maccy and CopyQ
- MonitorControl
- SF Symbols
- OpenVPN Connect
- Little Snitch PATH component
- Cursor and VS Code

Recommended:

- Prefer one clipboard manager.
- Prefer one primary terminal: Ghostty is installed and fits the requested direction.
- Avoid Karabiner-Elements, per request.
- Use native macOS features where possible.

## Missing Items for Requested Final Architecture

Required/recommended missing:

- `zoxide`
- `mise` or an explicit decision to avoid it
- `btop`
- `yq`
- `redis-cli` if Redis work is needed
- `git-lfs` command, because Git config references LFS filters
- `dev` cheatsheet
- `c` project selector
- `devtmux`
- `doctor`
- Proper `Brewfile`
- New architecture docs: `SETUP.md`, `COMMANDS.md`, `TROUBLESHOOTING.md`, `REMOVALS.md`
- Cursor rules templates under a project-safe path

Optional useful missing:

- `duf`
- `dust`
- `procs`
- `hyperfine`
- `watchexec`
- `shellcheck`

## Duplicated or Conflicting Areas

- Prompt: Powerlevel10k and Starship both installed; active config uses Powerlevel10k.
- Shell framework/plugin locations: multiple Oh My Zsh and plugin copies.
- Clipboard managers: Maccy and CopyQ.
- Container runtimes: OrbStack active, Colima installed.
- Runtime managers: NVM active, repo mentions fnm, user requested mise evaluation, Homebrew Node/pnpm also present.
- Terminals: Ghostty and Kitty installed; repo has Alacritty config and cask list still recommends Alacritty.
- GitHub/GitLab tools: both `gh` and `glab` installed.
- Editors: Cursor, VS Code, VSCodium, Sublime Text, Neovim.
- VS Code/Cursor extensions: many overlapping themes, Git tools, and AI assistants.

## Misconfigured or Risky Findings

- Broken `~/.zprofile` symlink.
- Active `~/.zshrc` does not match repo architecture.
- PATH has duplicates and hardcoded runtime paths.
- `c` conflicts with requested project selector.
- `z` unavailable.
- `gl` currently means `git pull`, not requested `git log`.
- `fastfetch` runs on every shell startup.
- `~/.zshrc` has personal/local project aliases and `pass="cat ~/pass.txt"`; this should not be put into portable dotfiles.
- `~/pass.txt` exists; do not copy it into dotfiles.
- SSH private keys exist; do not copy them into dotfiles.
- Git LFS config exists but `git-lfs` command is missing.
- `~/.config/nvim/.init.lua.swp` is stale editor state.
- Cursor terminal PATH hardcodes a specific Node version.
- Homebrew packages are significantly outdated.

## Recommended Changes for Later Phases

Do only after approval and backup.

1. Create `~/dotfiles-backup-YYYYMMDD-HHMMSS/`.
2. Decide canonical repo path: current `/Users/ablfaxl/project/dotfiles` vs old `/Users/ablfaxl/project/Github/dotfiles`.
3. Relink broken/stale dotfile symlinks to the canonical repo.
4. Replace active `~/.zshrc` with a clean modular ZSH setup.
5. Keep `z` reserved for `zoxide`; install/configure `zoxide`.
6. Create `dev` as interactive Finglish developer cheatsheet.
7. Create `c` as fzf project selector using detected existing project roots.
8. Create `devtmux` and `doctor`.
9. Standardize prompt on Starship unless you explicitly prefer Powerlevel10k.
10. Build a curated `Brewfile` rather than dumping everything installed.
11. Use OrbStack as the primary Docker runtime and mark Colima optional, unless you prefer Colima.
12. Choose one runtime management strategy: likely `mise`, or keep a simpler `fnm + uv + rustup` approach.
13. Convert Git config to a safe, portable repo-managed config with private identity in a local include.
14. Simplify VS Code/Cursor extension recommendations; do not mutate Cursor internals.
15. Incrementally clean Neovim without replacing it.

## Proposed Keep / Install / Skip Decisions

Preliminary only; final choices belong in Phase 2+.

| Tool | Decision | Reason |
| --- | --- | --- |
| ZSH | KEEP | Required preference and native macOS shell |
| Homebrew | KEEP | Best package manager for this setup |
| Starship | KEEP / ACTIVATE | Fast, portable, already installed |
| Powerlevel10k | DEPRECATE | Duplicate prompt complexity if Starship is used |
| Oh My Zsh | OPTIONAL | Existing setup uses it, but a lighter setup may be faster |
| zsh-autosuggestions | KEEP | Useful and lightweight |
| zsh-syntax-highlighting | KEEP | Useful and common |
| zsh-autocomplete | SKIP/OPTIONAL | Powerful but can add complexity/conflicts |
| fzf | KEEP | Core workflow tool |
| zoxide | INSTALL | Required for `z` navigation |
| eza | KEEP | Better listing UX |
| bat | KEEP | Better `cat`/preview UX |
| fd | KEEP | Fast find replacement |
| ripgrep | KEEP | Fast search |
| git-delta | KEEP | Better diffs |
| lazygit | KEEP | Excellent Git TUI |
| jq | KEEP | JSON CLI |
| yq | INSTALL | YAML CLI, listed but missing |
| btop | INSTALL | Requested `top = btop`; better monitor than `htop` |
| htop | OPTIONAL | Redundant if `btop` is installed |
| mise | EVALUATE | Could unify runtimes |
| nvm | DEPRECATE if mise/fnm chosen | Slow shell startup and hardcoded Node path |
| pnpm | KEEP | Preferred package manager |
| Bun | KEEP OPTIONAL | Useful, but do not make it mandatory |
| uv | KEEP | Modern Python tooling |
| rustup | KEEP | Right way to manage Rust |
| OrbStack | KEEP | Active Docker context |
| Colima | OPTIONAL/SKIP | Duplicate with OrbStack |
| Ghostty | KEEP | Installed, modern terminal |
| Kitty | OPTIONAL | Duplicate terminal |
| Alacritty | SKIP for macOS | Repo has config, but Ghostty is installed |
| Karabiner-Elements | SKIP | Explicitly not wanted |
| CopyQ/Maccy | CHOOSE ONE | Duplicate clipboard managers |
| dust/duf/procs | OPTIONAL | Useful, not essential |
| tldr/tealdeer | KEEP | `tealdeer` already installed |
| hyperfine | OPTIONAL | Benchmarking only |
| watchexec | OPTIONAL | Useful for automation/dev loops |

## Manual Configuration Still Needed

- GitHub CLI login: `gh auth login`
- SSH agent/key setup should be checked manually; sandbox could not query `ssh-add -l`.
- Decide whether to keep OrbStack only or support Colima too.
- Decide runtime manager: `mise` vs `fnm + uv + rustup`.
- Decide primary terminal: likely Ghostty.
- Decide clipboard manager: Maccy or CopyQ.

## Phase 1 Conclusion

Developer environment: NEEDS ATTENTION

This setup is usable today, but it is not yet clean, reproducible, or standardized. The highest-impact fixes are to repair stale symlinks, simplify ZSH startup, standardize PATH/runtime management, add missing requested commands, and move personal/local state out of portable dotfiles.
