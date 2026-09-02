# array's st build

This build tracks `st 0.9.2` and matches the WezTerm setup in
`~/.config/wezterm/wezterm.lua`: IosevkaTerm Nerd Font 12, Tokyo Night,
an opaque `#111117` background, and a 120x28 initial window.

The source lives in `~/nux/home/config/st` and is packaged for every Home
Manager host by `~/nux/modules/terminals/st.nix`.

## Features

- 10,000-line ring-buffer scrollback
- Mouse scrollback outside the alternate screen; native application scrolling
  inside `less`, `vim`, and other alternate-screen programs
- Xresources with runtime reload via `pkill -USR1 -x st`
- Alpha support, including the `-A` command-line option
- Anysize window sizing for tiling window managers
- Gapless box, block, and line drawing
- Unified X11 clipboard selection
- External pipe over the entire scrollback history
- URL opening through `xdg-open`

## Shortcuts

| Shortcut | Action |
| --- | --- |
| `Shift+PageUp` / `Shift+PageDown` | Scroll one page |
| Mouse wheel | Scroll three history lines |
| Drag beyond top/bottom edge | Scroll history while extending selection |
| `Shift+Left Click/Drag` | Extend an existing selection after scrolling |
| `Ctrl+Shift+C` / `Ctrl+Shift+V` | Copy / paste clipboard |
| `Ctrl+Shift+U` | Open the newest URL in history |
| `Ctrl+Shift+E` | Copy the full history to the clipboard |
| `Ctrl+Shift+PageUp` / `Ctrl+Shift+PageDown` | Increase / decrease font size |
| `Ctrl+Shift+Home` | Reset font size |

## Install

Apply the Home Manager configuration for the current host:

```sh
home-manager switch --flake ~/nux#"$NUX_HOST"
```

For an isolated local build while developing:

Fedora development headers are not installed on this machine, so build through
the existing Nix installation:

```sh
nix-shell -p pkg-config libx11 libxft fontconfig freetype libxrender --run 'make clean all'
```

The upstream patches merged into this tree are scrollback-ringbuffer,
scrollback-mouse, scrollback-mouse-altscreen, Xresources, alpha, expected-anysize,
boxdraw, clipboard, and externalpipe. Boxdraw, alpha, and full-history piping
were manually reconciled with the ring-buffer implementation.
