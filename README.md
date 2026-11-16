# zdawood.dev

My personal site. A static page written in Elm (`Browser.application`, so it owns its own
routing), styled with my personal brand, and built and served by Cloudflare Pages on every push to
`main`.

```sh
npm install
npm run build   # elm make --optimize → dist/elm.js, then public/ is copied into dist/
npm start       # build, then serve dist/ at http://localhost:8000 (deep links fall back to index.html)
```

## Layout

| Path | What |
|---|---|
| `src/Main.elm` | The whole site: routes, pages, view |
| `public/index.html` | The HTML shell: fonts, stylesheets, `Elm.Main.init()` |
| `public/brand.css` | The personal brand. A copy of `~/.claude/skills/personal-brand/brand.css`: change it there, then copy it here |
| `public/site.css` | The site's own layout on top of the brand |
| `scripts/serve.mjs` | A local server that behaves like Pages (a real file, else `index.html`) |

To add a page: add a `Route`, a parser line in `routeParser`, and a case in `view`.

## Cloudflare Pages (one time, in the dashboard)

1. Workers & Pages → Create → Pages → **Connect to Git** → pick `zfdawood/site`.
2. Build settings: framework preset **None**, build command `npm run build`, output directory `dist`.
   Add the environment variable `NODE_VERSION` = `22`.
3. Save and deploy. Each push to `main` deploys production, and other branches get preview URLs.
4. Custom domains → add `zdawood.dev` (and `www.zdawood.dev` if wanted). If the domain's DNS is on
   Cloudflare, the records are created for you.

There is deliberately no `404.html`: without one, Pages serves `index.html` for unknown paths, so
Elm's router handles deep links and shows its own not-found page.
