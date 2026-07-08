# firefox-themes

A modular `userChrome.css` theme system for Firefox. One theme is active
at a time, switching themes means editing a single line, and adding a
new theme means adding a new folder — nothing else in the system needs
to change.

## Folder structure

```
firefox-themes/
├── userChrome.css              # Chrome entry point. Imports config.css only.
├── config.css                  # CHROME THEME SWITCHER — uncomment one theme's theme.css.
├── userContent.css             # Content-page entry point (New Tab styling, if a theme has any).
├── themes/
│   ├── hover-titlebar/         # Auto-hide title bar, tabs, nav-bar, etc.
│   │   ├── theme.css           #   Chrome entry point (imports the three below).
│   │   ├── variables.css       #   Tunable numbers.
│   │   ├── layout.css          #   Structural rules.
│   │   ├── animations.css      #   Transitions & reveal triggers.
│   │   ├── content.css         #   New Tab landing page styling.
│   │   └── README.md           #   How this theme works + tuning guide.
│   └── _template/              # Skeleton for creating new themes.
│       ├── theme.css
│       └── content.css
└── README.md                   # This file.
```

`userChrome.css` never contains theme rules directly — it only ever
imports `config.css`, and `config.css` only ever imports whichever
theme folder is currently active. Themes never import each other or
reach outside their own folder, so they stay fully independent and
swappable.

Firefox treats chrome (toolbars/windows) and content (web pages) as two
separate documents with two separate stylesheets, so a theme's content
styling can't be pulled in through `theme.css` — it's wired up through
`userContent.css` instead. Not every theme needs this; `userContent.css`
only has an active import if the current theme ships a `content.css`.

## Installation

1. **Locate your Firefox profile folder.**
   In Firefox, go to `about:support` → *Profile Folder* → *Open Folder*.

2. **Create a `chrome` folder inside your profile**, if it doesn't
   already exist:

   ```
   <profile>/chrome/
   ```

3. **Copy the contents of this `firefox-themes/` folder** (not the
   folder itself) into `<profile>/chrome/`, so you end up with:

   ```
   <profile>/chrome/userChrome.css
   <profile>/chrome/config.css
   <profile>/chrome/themes/...
   ```

4. **Enable custom stylesheets.** In Firefox, go to `about:config` and
   set:

   | Preference                                          | Value  |
   |------------------------------------------------------|--------|
   | `toolkit.legacyUserProfileCustomizations.stylesheets` | `true` |

   This is required for `userChrome.css` to load at all — without it
   Firefox ignores the file completely.

5. **Restart Firefox** (chrome stylesheets are read at startup, not
   hot-reloaded).

### Preference required for the Hover Title Bar theme specifically

| Preference                | Value | Why                                                                                     |
|----------------------------|-------|-------------------------------------------------------------------------------------------|
| `browser.tabs.inTitlebar`  | `1`   | Draws window controls (minimize/maximize/close) as part of Firefox's own chrome, inside `#navigator-toolbox`, so this theme can hide/reveal them. Default is `1` on Windows/macOS and most Linux desktop environments with client-side decorations; some Linux window managers without CSD support may need it set explicitly, and a few won't support in-content window controls at all (see that theme's README for the caveat). |

## Switching themes

Open `config.css` and make sure exactly one `@import` line is
uncommented:

```css
@import url("themes/hover-titlebar/theme.css");

/* @import url("themes/_template/theme.css"); */
```

If the theme also ships a `content.css` (New Tab page styling), do the
same in `userContent.css` so the two stay matched. Save and restart
Firefox — that's the only file (or two, if content styling is involved)
you ever need to touch to change themes.

## Adding a new theme

1. Copy `themes/_template/` to `themes/<your-theme-name>/`.
2. Build out the theme's CSS (see `themes/hover-titlebar/` as a fully
   worked example of the variables/layout/animations split).
3. Add a `README.md` inside the theme folder documenting what it does.
4. Point `config.css` at your new theme's `theme.css` to try it.

No other file in the project needs to change — `userChrome.css` and the
other themes are untouched.

## Available themes

- **[hover-titlebar](themes/hover-titlebar/README.md)** — hides the
  title bar, tab bar, nav-bar, and address bar by default; reveals them
  with a smooth slide-down when hovering the top edge of the window.

## Compatibility notes

- Targets current Firefox releases (uses `:has()`, supported since
  Firefox 121 — well below any current release).
- CSS-only, no extensions or JS required beyond the two `about:config`
  prefs above.
- Firefox chrome selectors like `#navigator-toolbox` are internal UI
  IDs, not a public API — they've been stable for years but can change
  across major Firefox versions. If a theme stops working after a
  Firefox update, that's the first thing to check.
