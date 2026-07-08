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

The bookmarks toolbar (`#PersonalToolbar`) gets one extra rule on top of
that: `display: none !important;`, always on, not part of the hover
reveal at all. Firefox's default `browser.toolbars.bookmarks.visibility`
is `"newtab"`, which shows that bar only while `about:newtab` is the
active tab — since that's exactly the page this theme is built around,
it was popping back up and throwing off the `--hover-titlebar-height`
math (see Tuning below). Forcing it off sidesteps that regardless of
what the preference is set to.

The trick is **taking the toolbox out of document flow entirely** and
sliding it by animating `top`:

```css
#navigator-toolbox {
  position: fixed;
  top: calc(-1 * (var(--hover-titlebar-height) - var(--hover-titlebar-trigger)));
  left: 0; right: 0;
}
#tabbrowser-tabbox {
  margin-top: var(--hover-titlebar-trigger) !important;
}
```

Because `#navigator-toolbox` is `position: fixed`, it no longer occupies
any space in normal document flow, so it can never push
`#tabbrowser-tabbox` (the page content) around. The content area gets
exactly one fixed, permanent top offset — `--hover-titlebar-trigger`
(6px by default) — and that's it; it never changes size or position
again, whether the bar is hidden or revealed. That's what keeps the
window feeling like a fixed-size screen instead of reflowing/"shaking"
on every hover.

It's animated via `top` rather than `transform` deliberately: a real
`transform` on `#navigator-toolbox` would create a CSS containing block
for any `position: fixed` descendant, which would trap the `::after`
hint chevron (see below) inside the toolbox's own `overflow: hidden`
instead of letting it stay pinned to the viewport. `top` has no such
side effect.

That same `--hover-titlebar-trigger` gap is also the thin sliver of the
toolbox's own background that stays visible at y=0 — real DOM under
your cursor. Hover over it and `:hover` fires on `#navigator-toolbox`,
`top` animates to `0`, and the whole bar slides down *on top of* the
page content (it paints above it, per the toolbox's `z-index`) rather
than displacing it.

A plain sliver with nothing else around it isn't very discoverable on
its own, though, so a small chevron sits just below it — a gentle
bobbing arrow parked at the top-center of the window that fades out the
moment the bar is actually revealed (and respects
`prefers-reduced-motion`). It's rendered as `#navigator-toolbox::after`
but positioned `fixed` rather than `absolute`, which is what lets it
escape the toolbox's own `overflow: hidden` and sit against the window
instead of getting clipped along with the collapsed bar.

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
background and a faint fixed grid texture behind a single glassmorphic
(blurred, translucent) search box, dead-centered in the viewport with a
glow-on-hover/focus accent. Everything else Activity Stream normally
shows — the Firefox logo/wordmark, top-site tiles, and Pocket
story/recommendation cards — is hidden so the search box is the only
thing on the page. Colors live in a `:root` block at the top of
`content.css` (`--nt-accent`, `--nt-accent-2`, `--nt-bg-0/1`) — change
those to retheme it.

This is wired through `userContent.css` at the project root, not
`theme.css`, because Firefox loads chrome and page content as separate
documents (see the root `README.md`). It's scoped with `@-moz-document`
to `about:newtab` / `about:home` / `about:privatebrowsing` only.

Activity Stream (the New Tab page) isn't a stable public API — its
internal class names (`.search-wrapper`, `.logo-and-wordmark`,
`.top-sites`, `.sections`, etc.) have stayed the same for years but
*can* shift on a major Firefox version bump. If a selector stops
matching after an update — e.g. a hidden section reappears, or the
search box snaps back to its default top-of-page position — open
`about:newtab`, open the Browser Toolbox (`devtools.chrome.enabled` →
`true` in `about:config`, then Ctrl+Shift+Alt+I), inspect the element
in question, and swap in whatever class name it's using now. The
background/scrollbar rules target `body` directly and don't depend on
any of this.

## Limitations

- On Linux window managers that don't use client-side decorations, the
  minimize/maximize/close buttons are drawn by the window manager, not
  by Firefox — this theme can't hide those, only whatever Firefox
  itself renders (tabs, nav-bar, etc.). See the main `README.md` for
  the `browser.tabs.inTitlebar` preference.
- Full-screen video/PDF viewers that inject their own top overlays are
  outside this theme's scope.
