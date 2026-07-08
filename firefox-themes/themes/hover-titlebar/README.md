# Hover Title Bar

Hides Firefox's entire top chrome — window controls, tab bar, nav-bar,
address bar, extension icons, navigation buttons, overflow menu, and the
bookmarks toolbar (if you use one) — and reveals it with a smooth
slide-down animation when your cursor touches the top edge of the
window. Move away and it hides again.

## Files

| File            | Purpose                                              |
|-----------------|-------------------------------------------------------|
| `theme.css`      | Entry point — imports the three partials below.      |
| `variables.css`  | All tunable numbers in one place.                     |
| `layout.css`     | The structural collapse trick (no animation logic).   |
| `animations.css` | Transitions and the hover/focus/menu reveal triggers. |

## How it works

Firefox nests everything we want to hide inside one element:
`#navigator-toolbox` (titlebar + window buttons + tabs, nav-bar, and the
optional bookmarks toolbar). Hiding that single element hides all of it.

The trick is a **negative top margin equal to the toolbox's own height**:

```css
#navigator-toolbox {
  margin-top: calc(-1 * (var(--hover-titlebar-height) - var(--hover-titlebar-trigger)));
}
```

In CSS, an element's margin-top does not just move it visually — it also
changes how much vertical space it reserves in normal document flow.
When margin-top is the *negative* of the element's own height, its
margin-box collapses to roughly zero, so the page content sitting right
below it (`#tabbrowser-tabbox`) automatically slides up to fill the
freed space. That's why:

- there's no empty gap left behind while the bar is hidden, and
- the content area resizes correctly with no manual height math on the
  content side.

We don't push the margin *all* the way to `-height`, though — we leave
`--hover-titlebar-trigger` (2px by default) of margin unclaimed. That
means a hairline sliver of the toolbox's own background stays inside
the visible window at y=0. It's imperceptible to the eye, but it's real
DOM under your cursor — hover over it and `:hover` fires on
`#navigator-toolbox`, `margin-top` animates to `0`, and the whole bar
slides into view, pushing the page content back down.

Everything else in `animations.css` is about not hiding the bar out
from under you:

- `:focus-within` keeps it open while you're typing in the address bar.
- `:has(panel[panelopen])` / `:has(menupopup[open])` keep it open while
  a menu anchored to it (app menu, autocomplete, extension popup,
  bookmarks star panel, etc.) is open.
- The hide transition carries a `--hover-titlebar-hide-delay` so a
  quick cursor overshoot toward a menu doesn't snap the bar shut.

## Tuning

The one number you may need to adjust is `--hover-titlebar-height` in
`variables.css`. It has to be **greater than or equal to** the real
rendered height of your titlebar + tabs + nav-bar (+ bookmarks toolbar,
if shown), or a strip of chrome will stay stuck visible.

- **A visible strip of toolbar never fully hides** → increase
  `--hover-titlebar-height`.
- **The very top 1–2 rows of page content look clipped/covered** even
  after the bar is fully hidden → decrease `--hover-titlebar-height`.

Common values:

| Setup                                              | Approx. height |
|-----------------------------------------------------|----------------|
| Tabs + nav-bar only, default density                | 70–80px        |
| + Bookmarks toolbar always shown                    | 100–110px      |
| Large/touch UI density, or 2 rows of extension icons | 120px+         |

To find your exact number: temporarily set `--hover-titlebar-height: 0px`
(bar stays fully visible, unable to hide), open the Browser Toolbox
(`about:config` → `devtools.chrome.enabled` → `true`, then
Ctrl+Shift+Alt+I) and inspect `#navigator-toolbox`'s rendered height in
the layout panel.

## New Tab landing page (`content.css`)

Since this theme hides the chrome, the New Tab page is what you mostly
look at, so it gets its own look: a dark, slowly drifting aurora
background, a faint fixed grid texture, glassmorphic (blurred,
translucent) search box and top-site tiles with a glow-on-hover/focus
accent, and a matching thin accent scrollbar. Colors live in a `:root`
block at the top of `content.css` (`--nt-accent`, `--nt-accent-2`,
`--nt-bg-0/1`) — change those to retheme it.

This is wired through `userContent.css` at the project root, not
`theme.css`, because Firefox loads chrome and page content as separate
documents (see the root `README.md`). It's scoped with `@-moz-document`
to `about:newtab` / `about:home` / `about:privatebrowsing` only.

Activity Stream (the New Tab page) isn't a stable public API — its
internal class names (`.search-wrapper`, `.top-site-outer`, `.tile`,
`.card-outer`, etc.) have stayed the same for years but *can* shift on
a major Firefox version bump. If a selector stops matching after an
update, open `about:newtab`, open the Browser Toolbox
(`devtools.chrome.enabled` → `true` in `about:config`, then
Ctrl+Shift+Alt+I), inspect the element in question, and swap in
whatever class name it's using now. The background/scrollbar rules
target `body` directly and don't depend on any of this.

## Limitations

- On Linux window managers that don't use client-side decorations, the
  minimize/maximize/close buttons are drawn by the window manager, not
  by Firefox — this theme can't hide those, only whatever Firefox
  itself renders (tabs, nav-bar, etc.). See the main `README.md` for
  the `browser.tabs.inTitlebar` preference.
- Full-screen video/PDF viewers that inject their own top overlays are
  outside this theme's scope.
