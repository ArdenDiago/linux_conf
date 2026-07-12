# Keybindings Reference

Every keybinding installed by [`Full-Setup/arch/setup.sh`](setup.sh), grouped by
the tool that owns it. Source of truth is always the dotfile itself — this is
a readable index on top of them, not a replacement:

- Niri: [`dotfiles/niri/config.kdl`](dotfiles/niri/config.kdl)
- Hyprland: [`dotfiles/hypr/hyprland.conf`](dotfiles/hypr/hyprland.conf)
- Alacritty: [`dotfiles/alacritty/alacritty.toml`](dotfiles/alacritty/alacritty.toml)
- tmux: [`dotfiles/tmux/tmux.conf`](dotfiles/tmux/tmux.conf)
- ble.sh: [`dotfiles/blesh/blerc`](dotfiles/blesh/blerc)

`Mod` is the Super/Windows key in both compositors. Only one of Niri or
Hyprland runs at a time (picked from SDDM's session dropdown at login), but
both configs are installed side by side and kept in sync where possible.

## Niri (Wayland compositor)

| Keybind | Action |
|---|---|
| `Mod+Return` | Open a terminal (Alacritty) |
| `Mod+D` | App launcher (fuzzel) |
| `Mod+Alt+L` | Lock the screen (hyprlock) |
| `Mod+W` | Pick a wallpaper — centered carousel (`carousel.qml`, via Quickshell): h/j/k/l or arrows to browse, Enter to apply, Esc to cancel |
| `Mod+Q` | Close the focused window |
| `Mod+Left` / `Mod+Right` | Focus column left / right |
| `Mod+Up` / `Mod+Down` | Focus window up / down |
| `Mod+H` / `Mod+L` / `Mod+K` / `Mod+J` | vim-style equivalents of the arrow focus binds above |
| `Mod+Ctrl+Left` / `Mod+Ctrl+Right` | Move column left / right |
| `Mod+Ctrl+Up` / `Mod+Ctrl+Down` | Move window up / down |
| `Mod+Ctrl+K` / `Mod+Ctrl+J` | vim-style equivalents of move window up / down |
| `Mod+Alt+Shift+H` / `Mod+Alt+Shift+L` | vim-style equivalents of move column left / right (can't use `Mod+Ctrl+H/L` or `Mod+Alt+H/L` — already taken by focus-monitor and lock-screen) |
| `Mod+1` … `Mod+9` | Focus workspace 1–9 |
| `Mod+Ctrl+1` … `Mod+Ctrl+9` | Move focused column to workspace 1–9 |
| `Mod+I` / `Mod+U` | Focus workspace up / down |
| `Mod+Ctrl+I` / `Mod+Ctrl+U` | Move focused column to workspace up / down |
| `Mod+F` | Maximize the focused column |
| `Mod+Shift+F` | Fullscreen the focused window |
| `Mod+V` | Toggle floating for the focused window |
| `Mod+Grave` | Switch keyboard focus between the floating and tiling stacks (distinct from `Mod+V`, which toggles one window's floating state) |
| `Mod+BracketLeft` / `Mod+BracketRight` | Consume a window into the focused column from the left/right, or expel it back out |
| `Mod+Shift+H` / `Mod+Shift+L` | Resize focused column narrower / wider (∓10%) |
| `Mod+Shift+J` / `Mod+Shift+K` | Resize focused window shorter / taller (∓10%) |
| `Mod+R` | Cycle the focused column through niri's preset widths (1/3, 1/2, 2/3 of the output by default) |
| `Mod+Ctrl+H` / `Mod+Ctrl+L` | Focus the monitor to the left / right (HDMI-A-1 ↔ eDP-1) |
| `Mod+Ctrl+Shift+H` / `Mod+Ctrl+Shift+L` | Move focused column to the monitor left / right |
| `Print` / `Ctrl+Print` / `Alt+Print` | Screenshot: interactive area / full monitor / focused window |
| `XF86AudioRaiseVolume` / `XF86AudioLowerVolume` | Volume up / down (via `dms ipc call audio`) |
| `XF86AudioMute` / `XF86AudioMicMute` | Mute speaker / microphone |
| `XF86AudioPlay` / `XF86AudioPause` / `XF86AudioPrev` / `XF86AudioNext` | Media playback controls (via `dms ipc call mpris`) |
| `XF86MonBrightnessUp` / `XF86MonBrightnessDown` | Brightness up / down |
| `Mod+Space` | Spotlight app launcher (DMS) |
| `Mod+X` | Power menu (DMS) |
| `Mod+N` | Notification center (DMS) |
| `Mod+Shift+V` | Clipboard manager/history (DMS) — plain `Mod+V` is already floating-toggle above |
| `Mod+M` | Task manager / process list (DMS) |
| `Mod+Shift+N` | Notepad popup (DMS) |
| `Mod+Comma` | Settings panel (DMS) |
| `Mod+Y` | Browse wallpapers — DMS's own dankdash picker (separate from the `Mod+W` carousel above) |
| `Mod+Tab` | Overview of every window/workspace on the current monitor (same as the top-left hot corner) |
| `Mod+Shift+E` | Quit niri |
| `Mod+Shift+/` | Show the hotkey overlay (built-in cheat sheet) |

`Mod+Space`, `Mod+X`, `Mod+N`, `Mod+Shift+V`, `Mod+M`, `Mod+Shift+N`, `Mod+Comma`, `Mod+Y`, and the
media keys all call into [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell)'s
IPC (`dms ipc call ...`) — they need a running `dms run --session` to do anything. DMS itself isn't
installed by this repo (set up separately), so these binds are inert on a machine that doesn't have
it.

## Hyprland (Wayland compositor)

| Keybind | Action |
|---|---|
| `Super+Return` | Open a terminal (Alacritty) |
| `Super+D` | App launcher (fuzzel) |
| `Super+L` | Lock the screen (swaylock) |
| `Super+W` | Pick a wallpaper — centered carousel (`carousel.qml`, via Quickshell): h/j/k/l or arrows to browse, Enter to apply, Esc to cancel |
| `Super+Q` | Close the active window |
| `Super+V` | Toggle floating for the active window |
| `Super+F` | Toggle fullscreen |
| `Super+Shift+E` | Exit Hyprland |
| `Super+Left/Right/Up/Down` | Move focus in that direction |
| `Super+1` … `Super+9` | Switch to workspace 1–9 |
| `Super+Shift+1` … `Super+Shift+9` | Move active window to workspace 1–9 |
| `Super+drag` (left mouse button) | Move a floating window |
| `Super+drag` (right mouse button) | Resize a floating window |
| `Super+Shift+Left/Right/Up/Down` (hold, repeats) | Resize the active tiled window/split by 20px per tick |

## Alacritty (terminal emulator)

Alacritty itself only remaps `Shift+Return` for a literal newline; everything
else below is Alacritty capturing a key combo and sending a private escape
sequence that `tmux.conf` translates into a real tmux command (needed because
most terminals can't tell `Ctrl+Shift+<key>` apart from plain `Ctrl+<key>`).

| Keybind | Action |
|---|---|
| `Shift+Return` | Insert a literal newline (instead of submitting) |
| `Ctrl+Shift+D` | Split tmux pane horizontally (top/bottom) |
| `Ctrl+Alt+D` | Split tmux pane vertically (left/right) |
| `Ctrl+Alt+Left/Right/Up/Down` | Move focus between tmux panes |
| `Ctrl+Shift+H` | Pick one of the last 10 tmux sessions to switch to |
| `Ctrl+Shift+X` | Close only the current tmux pane (rest of the session, and the terminal window, keep running) |
| `Ctrl+Alt+X` | Kill the whole tmux session — closes the terminal window too, since Alacritty's shell *is* that session |
| `Ctrl+Shift+M` | Minimize the Alacritty window (no title bar, since decorations are off) |
| `Ctrl+N` | Open a new Alacritty window (starts a fresh tmux session) |

## tmux

Prefix-based bindings still use tmux's own default prefix (`Ctrl+B`) unless
noted. The pane/session bindings below are actually driven by Alacritty (see
above) via `user-keys`, not typed directly into tmux.

| Keybind | Action |
|---|---|
| `Ctrl+Shift+D` *(via Alacritty)* | Split pane horizontally |
| `Ctrl+Alt+D` *(via Alacritty)* | Split pane vertically |
| `Ctrl+Alt+Left/Right/Up/Down` *(via Alacritty)* | Move focus between panes |
| `Ctrl+Shift+H` *(via Alacritty)* | Choose a session to switch to (`choose-tree -Zs`) |
| `Ctrl+Shift+X` *(via Alacritty)* | Close only the current pane |
| `Ctrl+Alt+X` *(via Alacritty)* | Kill the whole session (and the terminal window with it) |
| Mouse scroll (in a pane) | Enter copy-mode and scroll back through history |
| Mouse click/drag | Select a pane / resize a pane border |
| `Space` *(in copy-mode)* | Begin selection (vi-style copy-mode default) |
| `Enter` *(in copy-mode)* | Copy selection to the system clipboard (`wl-copy`) and exit copy-mode |
| `prefix + t` | Big popup clock (12h, AM/PM, day + date) — overrides tmux's stock clock-mode |
| `prefix + Left/Right/Up/Down` or `prefix + h/j/k/l` (repeatable) | Resize the active pane by 5 cells in that direction — first tap needs the prefix, further taps/holds within 700ms don't |

## ble.sh (bash line editor)

`modules/25-ble-sh.sh` installs [ble.sh](https://github.com/akinomyoga/ble.sh) for
fish/zsh-style ghost-text autosuggestions (grey text predicted from history) and
syntax highlighting in bash. `blerc` touches the autosuggestion color, Tab's
completion behavior, and how Enter/Ctrl+U handle multi-line input — everything
else is ble.sh's stock behavior.

| Keybind | Action |
|---|---|
| `Tab` (suggestion showing) | Accept the next path segment (up to the next `/`) of the grey autosuggestion; a non-path suggestion (no `/`) is accepted in full. Pressing `Tab` again with nothing left to segment falls through to normal completion (e.g. a command's flags/subcommands) |
| `End` / `C-f` / `Right` / `C-e` | Accept the whole grey autosuggestion at once — only while one is showing and the cursor is at end-of-line |
| `Shift+Enter` | Accept the autosuggestion regardless of cursor position |
| `Ctrl+G` | Dismiss the current autosuggestion |
| `Enter` | Run the command — including a multi-line paste, immediately, no separate confirmation step |
| `Ctrl+U` | Clear the entire input buffer (not just back to the start of the current line) |

`Tab`'s per-segment accept is custom (`ble/widget/auto_complete/insert-path-segment`
in `blerc`, bound to both `TAB` and `C-i` since a physical Tab keypress can decode
as either depending on terminal negotiation), replacing ble.sh's plain "accept
everything" default: history-based suggestions default to your most-used past
path, which is often wrong once you're headed somewhere that only shares a
prefix with it — accepting one segment at a time lets you type past a stale
suggestion instead of it barreling ahead of you.

`Enter`/`Ctrl+U` on multi-line input are also custom. Stock ble.sh pauses on a
pasted multi-line command with a `-- MULTILINE --` prompt (`RET`/`C-m` insert
another newline, only `C-j` actually runs it), and `Ctrl+U` only kills back to
the start of the current line. `blerc` rebinds `RET`/`C-m` straight to
`accept-line` (so Enter always runs it, matching `C-j`, and the now-stale
"insert a newline / C-j: run" hint is dropped from the status line) and adds a
`kill-whole-buffer` widget on `Ctrl+U` so it clears the whole pasted block
regardless of cursor position.

## Neovim / LazyVim

`modules/10-lazyvim.sh` clones the vanilla [LazyVim starter](https://github.com/LazyVim/starter)
as-is with no custom keymaps layered on top, so there's nothing script-specific
to document here. Use LazyVim's own keymap reference:
`:help lazyvim` inside Neovim, or the
[LazyVim default keymaps docs](https://www.lazyvim.org/keymaps).
