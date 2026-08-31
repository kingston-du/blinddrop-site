# blinddrop-site

The one web surface for [Blind Drop](https://testflight.apple.com/join/qTcTqBkx) — a daily
blind music-guessing game for one private group of friends.

Two pages, no framework, no build step, no dependencies. Open `index.html` in a browser and
that is the site.

```
index.html      the landing page
j/index.html    the invite fallback — https://blinddrop.app/j/<CODE>
assets/         style.css, the Bricolage Grotesque variable font (SIL OFL), images
.well-known/    apple-app-site-association
vercel.json     rewrites + the association file's Content-Type
_headers        the Cloudflare Pages equivalent, kept in sync
verify.sh       post-deploy checks
```

## Scope

Deliberately one page plus the invite fallback. The app repo's `docs/16` §3 and the `E27-03`
spike both landed on this and no more: app name, one screenshot, one line of copy, an install
link, and the raw code when the universal link does not resolve. No accounts, no group data,
no forms, no analytics.

Adding pages, a blog, or a waitlist reopens a decision that was made deliberately. It needs the
owner, not a pull request.

## Design

Every colour, size and face is ported from the app's design system — `docs/07-DESIGN-SYSTEM.md`
in the app repo — and `assets/style.css` names its source at the top. **Do not invent a value
here.** If the palette changes, it changes in the app first and is copied across.

The two accents are semantic and never decorative: **amber means sealed**, **ultramarine means
revealed**. The app allows both on one screen in exactly two places — the reveal transition and
*How to play*, which is the legend. This page is both of those things at once, which is why it
carries both:

- the flight in the hero goes amber → ultramarine, which *is* the reveal transition;
- the four phases are the legend, so step 1 (the blind window) is amber and steps 2–4 are not.

Everything else stays neutral, the install button included. Installing is not a phase of a
round, so it takes no accent.

There are no shadows, no gradients and no dark mode, for the same reasons the app has none.

## Local preview

No tooling. Any static server:

```bash
python3 -m http.server 4321
```

Then open <http://127.0.0.1:4321/>. Note that `/j/<CODE>` needs the rewrite in `vercel.json`,
which a plain file server will not do — visit `/j/index.html` to see the fallback state, or
deploy a preview.

## Deploying

Vercel, as a static project — no framework preset, no build command, output directory `.`.
`vercel.json` carries the two things that matter:

- `/j/:code` rewrites to `j/index.html`, so an invite code renders instead of 404ing;
- `/.well-known/apple-app-site-association` is served as `application/json`.

`_headers` is the same header rule in Cloudflare Pages' format, so switching hosts is a
one-file decision.

After every deploy that touches routing, headers or the association file:

```bash
./verify.sh https://blinddrop.app
```

## The association file, and the thing that will break

`.well-known/apple-app-site-association` is a **copy** of the one in the app repo at
`web/.well-known/apple-app-site-association`. The app repo is the source of truth: its
`applinks:blinddrop.app` entitlement and the App ID prefix in that file have to agree, and a
mismatched prefix disables every universal link silently.

Two copies can drift. `verify.sh` diffs the deployed file against the committed one, which is
the check that catches it. Apple's own requirements are equally unforgiving and all enforced:
`application/json`, no file extension, no redirects, valid TLS.

**Universal links only ever resolve on `blinddrop.app`.** On a `*.vercel.app` or `*.pages.dev`
address the association file is inert — the entitlement claims one domain and that is the only
domain iOS will check. Until the domain is registered and pointed here, `/j/<CODE>` can show a
code for manual entry but cannot open the app, and the Spotify OAuth callback the app expects
at `https://blinddrop.app/spotify-auth` has nowhere to land either.

## Licence

`assets/fonts/BricolageGrotesque.ttf` is SIL Open Font License 1.1; the licence sits beside it
in `assets/fonts/OFL.txt`.
