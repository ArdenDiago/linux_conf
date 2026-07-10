# Keybindings Reference

Every keybinding installed by [`Full-Setup/arch/setup.sh`](setup.sh), grouped by
the tool that owns it. Source of truth is always the dotfile itself — this is
a readable index on top of them, not a replacement:

- Niri: [`dotfiles/niri/config.kdl`](dotfiles/niri/config.kdl)
- Hyprland: [`dotfiles/hypr/hyprland.conf`](dotfiles/hypr/hyprland.conf)
- Alacritty: [`dotfiles/alacritty/alacritty.toml`](dotfiles/alacritty/alacritty.toml)
- tmux: [`dotfiles/tmux/tmux.conf`](dotfiles/tmux/tmux.conf)
- Waybar (mouse clicks, not keybinds): [`dotfiles/waybar/config-niri.jsonc`](dotfiles/waybar/config-niri.jsonc), [`dotfiles/waybar/config-hyprland.jsonc`](dotfiles/waybar/config-hyprland.jsonc)

`Mod` is the Super/Windows key in both compositors. Only one of Niri or
Hyprland runs at a time (picked from SDDM's session dropdown at login), but
both configs are installed side by side and kept in sync where possible.

## Niri (Wayland compositor)

| Keybind | Action |
|---|---|
| `Mod+Return` | Open a terminal (Alacritty) |
| `Mod+D` | App launcher (fuzzel) |
| `Mod+L` | Lock the screen (swaylock) |
| `Mod+W` | Pick a wallpaper (fuzzel picker with thumbnails) |
| `Mod+Q` | Close the focused window |
| `Mod+Left` / `Mod+Right` | Focus column left / right |
| `Mod+Up` / `Mod+Down` | Focus window up / down |
| `Mod+Ctrl+Left` / `Mod+Ctrl+Right` | Move column left / right |
| `Mod+Ctrl+Up` / `Mod+Ctrl+Down` | Move window up / down |
| `Mod+1` … `Mod+9` | Focus workspace 1–9 |
| `Mod+Ctrl+1` … `Mod+Ctrl+9` | Move focused column to workspace 1–9 |
| `Mod+F` | Maximize the focused column |
| `Mod+Shift+F` | Fullscreen the focused window |
| `Mod+V` | Toggle floating for the focused window |
| `Mod+Shift+E` | Quit niri |
| `Mod+Shift+/` | Show the hotkey overlay (built-in cheat sheet) |

## Hyprland (Wayland compositor)

| Keybind | Action |
|---|---|
| `Super+Return` | Open a terminal (Alacritty) |
| `Super+D` | App launcher (fuzzel) |
| `Super+L` | Lock the screen (swaylock) |
| `Super+W` | Pick a wallpaper (fuzzel picker with thumbnails) |
| `Super+Q` | Close the active window |
| `Super+V` | Toggle floating for the active window |
| `Super+F` | Toggle fullscreen |
| `Super+Shift+E` | Exit Hyprland |
| `Super+Left/Right/Up/Down` | Move focus in that direction |
| `Super+1` … `Super+9` | Switch to workspace 1–9 |
| `Super+Shift+1` … `Super+Shift+9` | Move active window to workspace 1–9 |
| `Super+drag` (left mouse button) | Move a floating window |
| `Super+drag` (right mouse button) | Resize a floating window |

## Waybar (mouse clicks, not keyboard — listed for completeness)

Same across both the niri and Hyprland waybar configs unless noted.

| Module | Click | Action |
|---|---|---|
| Workspaces (Hyprland only) | Left click | Switch to that workspace |
| App launcher widget | Left click | Open fuzzel |
| CPU widget | Left click | Open `btop` in a terminal |
| Memory widget | Left click | Open `btop` in a terminal |
| Volume widget | Right click | Mute/unmute (`pamixer -t`) |
| Media/player widget | Left click | Play/pause (`playerctl play-pause`) |
| Updates widget | Left click | Open `sudo pacman -Syu` in a terminal |
| Game-mode widget (Hyprland only) | Left click | Toggle animations/blur off for gaming |

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
| `Ctrl+Shift+X` | Kill the current tmux session (and the terminal window with it) |
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
| `Ctrl+Shift+X` *(via Alacritty)* | Kill the current session |
| Mouse scroll (in a pane) | Enter copy-mode and scroll back through history |
| Mouse click/drag | Select a pane / resize a pane border |
| `Space` *(in copy-mode)* | Begin selection (vi-style copy-mode default) |
| `Enter` *(in copy-mode)* | Copy selection to the system clipboard (`wl-copy`) and exit copy-mode |
| `prefix + t` | Big popup clock (12h, AM/PM, day + date) — overrides tmux's stock clock-mode |

## Neovim / LazyVim

`modules/10-lazyvim.sh` clones the vanilla [LazyVim starter](https://github.com/LazyVim/starter)
as-is with no custom keymaps layered on top, so there's nothing script-specific
to document here. Use LazyVim's own keymap reference:
`:help lazyvim` inside Neovim, or the
[LazyVim default keymaps docs](https://www.lazyvim.org/keymaps).
